
# # resource azurerm_role_assignment demo_admin {
# #   scope                        = azurerm_resource_group.app_rg.id
# #   role_definition_name         = "Contributor"
# #   principal_id                 = var.admin_object_id

# #   count                        = var.admin_object_id != null ? 1 : 0
# # }

# resource azurerm_storage_account app_storage {
#   name                         = "${local.resource_group_name_short}stor"
#   location                     = azurerm_resource_group.app_rg.location
#   resource_group_name          = azurerm_resource_group.app_rg.name
#   account_kind                 = "StorageV2"
#   account_tier                 = "Standard"
#   account_replication_type     = var.storage_replication_type
#   enable_https_traffic_only    = true
 
#   provisioner "local-exec" {
#     # TODO: Add --auth-mode login once supported
#     command                    = "az storage logging update --account-name ${self.name} --log rwd --retention 90 --services b"
#   }

#   timeouts {
#     create                     = var.default_create_timeout
#     update                     = var.default_update_timeout
#     read                       = var.default_read_timeout
#     delete                     = var.default_delete_timeout
#   }  

#   tags                         = var.tags
  
#   depends_on                   = [
#                                   azurerm_app_service_virtual_network_swift_connection.network,
#                                   # FIX for race condition: Error waiting for Azure Storage Account "vdccipaasappb1375stor" to be created: Future#WaitForCompletion: the number of retries has been exceeded: StatusCode=400 -- Original Error: Code="NetworkAclsValidationFailure" Message="Validation of network acls failure: SubnetsNotProvisioned:Cannot proceed with operation because subnets appservice of the virtual network /subscriptions//resourceGroups/vdc-ci-b1375/providers/Microsoft.Network/virtualNetworks/vdc-ci-b1375-paas-spoke-network are not provisioned. They are in Updating state.."
#                                   azurerm_storage_container.archive_storage_container
#   ]
# }
# resource azurerm_private_endpoint app_blob_storage_endpoint {
#   name                         = "${azurerm_storage_account.app_storage.name}-blob-endpoint"
#   resource_group_name          = azurerm_resource_group.app_rg.name
#   location                     = azurerm_resource_group.app_rg.location
#   subnet_id                    = var.data_subnet_id

#   private_service_connection {
#     is_manual_connection       = false
#     name                       = "${azurerm_storage_account.app_storage.name}-blob-endpoint-connection"
#     private_connection_resource_id = azurerm_storage_account.app_storage.id
#     subresource_names          = ["blob"]
#   }

#   timeouts {
#     create                     = var.default_create_timeout
#     update                     = var.default_update_timeout
#     read                       = var.default_read_timeout
#     delete                     = var.default_delete_timeout
#   }  

#   tags                         = var.tags
#   count                        = var.enable_private_link ? 1 : 0
# }
# resource azurerm_private_dns_a_record app_blob_storage_dns_record {
#   name                         = azurerm_storage_account.app_storage.name
#   zone_name                    = "privatelink.blob.core.windows.net"
#   resource_group_name          = local.vdc_resource_group_name
#   ttl                          = 300
#   records                      = [azurerm_private_endpoint.app_blob_storage_endpoint.0.private_service_connection[0].private_ip_address]

#   tags                         = var.tags
#   count                        = var.enable_private_link ? 1 : 0
# }
# resource azurerm_private_endpoint app_table_storage_endpoint {
#   name                         = "${azurerm_storage_account.app_storage.name}-table-endpoint"
#   resource_group_name          = azurerm_resource_group.app_rg.name
#   location                     = azurerm_resource_group.app_rg.location
#   subnet_id                    = var.data_subnet_id

#   private_service_connection {
#     is_manual_connection       = false
#     name                       = "${azurerm_storage_account.app_storage.name}-table-endpoint-connection"
#     private_connection_resource_id = azurerm_storage_account.app_storage.id
#     subresource_names          = ["table"]
#   }

#   timeouts {
#     create                     = var.default_create_timeout
#     update                     = var.default_update_timeout
#     read                       = var.default_read_timeout
#     delete                     = var.default_delete_timeout
#   }  

#   tags                         = var.tags
#   count                        = var.enable_private_link ? 1 : 0
#   # Create Private Endpoints one at a time
#   depends_on                   = [azurerm_private_endpoint.app_blob_storage_endpoint]
# }
# resource azurerm_private_dns_a_record app_table_storage_dns_record {
#   name                         = azurerm_storage_account.app_storage.name
#   zone_name                    = "privatelink.table.core.windows.net"
#   resource_group_name          = local.vdc_resource_group_name
#   ttl                          = 300
#   records                      = [azurerm_private_endpoint.app_table_storage_endpoint.0.private_service_connection[0].private_ip_address]

#   tags                         = var.tags
#   count                        = var.enable_private_link ? 1 : 0
# }
# resource azurerm_advanced_threat_protection app_storage {
#   target_resource_id           = azurerm_storage_account.app_storage.id
#   enabled                      = true
# }
# resource azurerm_storage_container app_storage_container {
#   name                         = "data"
#   storage_account_name         = azurerm_storage_account.app_storage.name
#   container_access_type        = "private"

#   count                        = var.storage_import ? 1 : 0

# # depends_on                   = [azurerm_storage_account_network_rules.app_storage]
# }
# resource azurerm_storage_blob app_storage_blob_sample {
#   name                         = "sample.txt"
#   storage_account_name         = azurerm_storage_account.app_storage.name
#   storage_container_name       = azurerm_storage_container.app_storage_container.0.name

#   type                         = "Block"
#   source                       = "../data/sample.txt"

#   count                        = var.storage_import ? 1 : 0
# }