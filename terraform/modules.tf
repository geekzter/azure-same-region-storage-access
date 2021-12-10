module storage {
  source                       = "./modules/storage"

  admin_ips                    = [local.ip_prefix]
  data_owner_object_id         = data.azurerm_client_config.current.object_id
  location                     = var.location
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = azurerm_resource_group.rg.tags
}