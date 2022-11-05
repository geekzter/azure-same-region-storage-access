output location {
  value       = azurerm_resource_group.rg.location
}

output resource_group_name {
  value       = azurerm_resource_group.rg.name
}

output subscription_id {
  value       = data.azurerm_subscription.primary.subscription_id
}

output storage_account_name {
  value       = module.storage.name
}

output storage_sas {
  sensitive   = true
  value       = module.storage.storage_sas
}

output storage_url {
  value       = module.storage.storage_url
}