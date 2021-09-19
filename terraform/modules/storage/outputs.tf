output blob_url {
  sensitive   = true
  value       = "${azurerm_storage_blob.app_storage_blob_sample.url}${data.azurerm_storage_account_sas.app_storage.sas}"
}

output name {
  value       = azurerm_storage_account.app_storage.name
}