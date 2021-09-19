locals {
  resource_group_name_short    = substr(lower(replace(var.resource_group_name,"-","")),0,20)
}

resource azurerm_storage_account app_storage {
  name                         = "${local.resource_group_name_short}stor"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  enable_https_traffic_only    = true
 
  provisioner "local-exec" {
    # TODO: Add --auth-mode login once supported
    command                    = "az storage logging update --account-name ${self.name} --log rwd --retention 90 --services b"
  }

  tags                         = var.tags
}
resource azurerm_role_assignment tf_data_owner {
  scope                        = azurerm_storage_account.app_storage.id
  role_definition_name         = "Storage Blob Data Owner"
  principal_id                 = var.data_owner_object_id

  count                        = var.data_owner_object_id != null ? 1 : 0
}
resource azurerm_storage_account_network_rules app_storage {
  resource_group_name          = var.resource_group_name
  storage_account_name         = azurerm_storage_account.app_storage.name
  bypass                       = ["None"]
  default_action               = "Deny"
  ip_rules                     = var.admin_ips

  depends_on                   = [azurerm_storage_container.app_storage_container,azurerm_storage_blob.app_storage_blob_sample]
}

resource azurerm_storage_container app_storage_container {
  name                         = "data"
  storage_account_name         = azurerm_storage_account.app_storage.name
  container_access_type        = "private"

  # Creating FW rules prior to accessing storage container will fail if Terraform is run from the same Azure region
  # depends_on                   = [azurerm_storage_account_network_rules.app_storage]
}
resource azurerm_storage_blob app_storage_blob_sample {
  name                         = "sample.txt"
  storage_account_name         = azurerm_storage_account.app_storage.name
  storage_container_name       = azurerm_storage_container.app_storage_container.name

  type                         = "Block"
  source                       = "../data/sample.txt"
}