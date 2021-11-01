output location {
  value       = azurerm_resource_group.rg.location
}

output resource_group_name {
  value       = azurerm_resource_group.rg.name
}

output storage_account_name {
  value       = module.storage.name
}

output storage_blob_url {
  sensitive   = true
  value       = module.storage.blob_url
}