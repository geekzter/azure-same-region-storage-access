module virtual_network {
  source                       = "./modules/virtual-network"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  tags                         = azurerm_resource_group.rg.tags

  address_space                = cidrsubnet(var.address_space,4,0)
  deploy_bastion               = false
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
}