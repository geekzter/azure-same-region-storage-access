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
    command                    = "az storage logging update --account-name ${self.name} --log rwd --retention 90 --services b --subscription ${split("/",self.id)[2]}"
  }

  tags                         = var.tags
}

resource azurerm_storage_account_network_rules app_storage {
  storage_account_id           = azurerm_storage_account.app_storage.id
  bypass                       = ["None"]
  default_action               = "Deny"
  ip_rules                     = var.admin_ips
}

resource time_offset sas_expiry {
  offset_years                 = 1
}
resource time_offset sas_start {
  offset_days                  = -10
}
data azurerm_storage_account_sas app_storage {
  connection_string            = azurerm_storage_account.app_storage.primary_connection_string
  https_only                   = true

  resource_types {
    service                    = true
    container                  = true
    object                     = true
  }

  services {
    blob                       = true
    queue                      = false
    table                      = false
    file                       = false
  }

  start                        = time_offset.sas_start.rfc3339
  expiry                       = time_offset.sas_expiry.rfc3339  

  permissions {
    add                        = false
    create                     = false
    delete                     = false
    filter                     = false
    list                       = true
    process                    = false
    read                       = true
    tag                        = false
    update                     = false
    write                      = false
  }
}