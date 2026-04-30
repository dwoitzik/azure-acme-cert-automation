output "function_app_name" {
  description = "The name of the deployed Function App."
  value       = azurerm_windows_function_app.acmebot.name
}

output "function_app_default_hostname" {
  description = "The default URL of the Function App (Acmebot Dashboard)."
  value       = "https://${azurerm_windows_function_app.acmebot.default_hostname}/dashboard"
}

output "key_vault_name" {
  description = "The name of the Key Vault where certificates are stored."
  value       = azurerm_key_vault.acmebot_kv.name
}

output "instruction" {
  description = "Next steps for the user."
  value       = "Deployment successful! Please visit the dashboard URL above and ensure you have enabled App Service Authentication as described in the README."
}