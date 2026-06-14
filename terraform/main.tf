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
  #checkov:skip=CKV_AZURE_59:   Public network access is required for the Consumption plan (no VNet integration). Private Endpoint isolation is included in the Enterprise Edition — woitzik.dev/templates
  #checkov:skip=CKV_AZURE_190:  Public blob access is disabled via allow_nested_items_to_be_public — this check is a false positive.
  #checkov:skip=CKV_AZURE_206:  LRS replication is sufficient for cert automation workloads. ZRS/GRS is available in the Enterprise Edition.
  #checkov:skip=CKV2_AZURE_33:  Private Endpoint for storage requires VNet integration, included in the Enterprise Edition — woitzik.dev/templates
  #checkov:skip=CKV2_AZURE_40:  Function App requires Shared Key access via storage_account_access_key — MSI-based storage auth is not supported by azurerm_windows_function_app.
  #checkov:skip=CKV2_AZURE_41:  SAS expiration policy is not applicable — the storage account relies on the Function App's MSI, not SAS tokens.
  #checkov:skip=CKV2_AZURE_47:  Anonymous blob access is implicitly disabled; no public containers are created.
  #checkov:skip=CKV2_AZURE_1:   Customer-Managed Key encryption is out of scope for this base module.
  name                            = "stacmebot${lower(var.environment)}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_service_plan" "acmebot_plan" {
  #checkov:skip=CKV_AZURE_211: Y1 Consumption plan is intentional for serverless cert automation. Production P1v3 with zone balancing is included in the Enterprise Edition — woitzik.dev/templates
  #checkov:skip=CKV_AZURE_212: Minimum instance count is not applicable to Consumption plans.
  #checkov:skip=CKV_AZURE_225: Zone redundancy is not supported on Consumption plans.
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
  #checkov:skip=CKV_AZURE_109:  KV network firewall rules require VNet integration, included in the Enterprise Edition — woitzik.dev/templates
  #checkov:skip=CKV_AZURE_189:  Public network access is required for the Consumption plan (no VNet). Private Endpoint isolation is included in the Enterprise Edition.
  #checkov:skip=CKV2_AZURE_32:  Private Endpoint for Key Vault requires VNet integration, included in the Enterprise Edition — woitzik.dev/templates
  name                       = "kv-acmebot-${var.environment}-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  tags                       = var.tags
}

## ===========================================================
## Function App (The Acmebot Engine)
## ===========================================================

resource "azurerm_windows_function_app" "acmebot" {
  name                = "func-acmebot-${var.environment}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  service_plan_id = azurerm_service_plan.acmebot_plan.id
  #checkov:skip=CKV_AZURE_221: Public network access is required for the Consumption plan (no VNet integration). Private Endpoint isolation is included in the Enterprise Edition — woitzik.dev/templates
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
