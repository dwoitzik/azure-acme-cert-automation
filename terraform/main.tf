data "azurerm_client_config" "current" {}

## ===========================================================
## Resource Group
## ===========================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

## ===========================================================
## Entra ID (Azure AD) App Registration for Acmebot Auth
## ===========================================================

resource "azuread_application" "acmebot" {
  display_name = "app-acmebot-${var.environment}"

  web {
    redirect_uris = ["https://func-acmebot-${var.environment}-${random_string.suffix.result}.azurewebsites.net/.auth/login/aad/callback"]
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}

resource "azuread_service_principal" "acmebot" {
  client_id = azuread_application.acmebot.client_id
}

resource "azuread_application_password" "acmebot" {
  application_id = azuread_application.acmebot.id
  end_date       = "2099-01-01T00:00:00Z"
}

## ===========================================================
## Storage & App Service Plan (Serverless / Consumption)
## ===========================================================

resource "azurerm_storage_account" "acmebot_storage" {
  name                     = "stacmebot${lower(var.environment)}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_service_plan" "acmebot_plan" {
  name                = "asp-acmebot-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "Y1" # Serverless Consumption Plan
  tags                = var.tags
}

## ===========================================================
## Key Vault for Certificates
## ===========================================================

resource "azurerm_key_vault" "acmebot_kv" {
  name                      = "kv-acmebot-${var.environment}-${random_string.suffix.result}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  tags                      = var.tags
}

## ===========================================================
## Function App (The Acmebot Engine)
## ===========================================================

resource "azurerm_windows_function_app" "acmebot" {
  name                = "func-acmebot-${var.environment}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  service_plan_id            = azurerm_service_plan.acmebot_plan.id
  storage_account_name       = azurerm_storage_account.acmebot_storage.name
  storage_account_access_key = azurerm_storage_account.acmebot_storage.primary_access_key
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    default_provider       = "azureactivedirectory"
    unauthenticated_action = "RedirectToLoginPage"

    active_directory_v2 {
      client_id                  = azuread_application.acmebot.client_id
      tenant_auth_endpoint       = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/v2.0"
      client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
    }
    login {
      token_store_enabled = true
    }
  }

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                 = "https://stacmebotprod.blob.core.windows.net/keyvault-acmebot/v4/latest.zip"
    "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET" = azuread_application_password.acmebot.value
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "FUNCTIONS_INPROC_NET8_ENABLED"            = "1"
    "Acmebot:VaultBaseUrl"                     = azurerm_key_vault.acmebot_kv.vault_uri
    "Acmebot:Contacts"                         = var.acme_contact_email
    "Acmebot:Endpoint"                         = "https://acme-v02.api.letsencrypt.org/"
    "Acmebot:Environment"                      = "AzureCloud"
    "Acmebot:AzureDns:SubscriptionId"          = data.azurerm_client_config.current.subscription_id
  }

  tags = var.tags
}

## ===========================================================
## RBAC Role Assignments (Zero-Trust Identity)
## ===========================================================

resource "azurerm_role_assignment" "acmebot_dns" {
  scope                = var.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_windows_function_app.acmebot.identity[0].principal_id
}

resource "azurerm_role_assignment" "acmebot_kv" {
  scope                = azurerm_key_vault.acmebot_kv.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_windows_function_app.acmebot.identity[0].principal_id
}