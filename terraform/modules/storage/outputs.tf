output storage_sas {
  sensitive   = true
  value       = data.azurerm_storage_account_sas.app_storage.sas
}

output storage_url {
  value       = azurerm_storage_account.app_storage.primary_blob_endpoint
}

output name {
  value       = azurerm_storage_account.app_storage.name
}