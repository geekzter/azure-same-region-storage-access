# module virtual_network {
#   source                       = "./modules/virtual-network"

#   address_space                = cidrsubnet(var.address_space,4,0)
#   deploy_bastion               = false
#   location                     = var.location
#   log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
#   resource_group_name          = azurerm_resource_group.rg.name
#   tags                         = azurerm_resource_group.rg.tags
# }

module storage {
  source                       = "./modules/storage"

  admin_ips                    = local.admin_cidr_ranges
  data_owner_object_id         = local.automation_object_id
  location                     = var.location
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = azurerm_resource_group.rg.tags
}