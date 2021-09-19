data azurerm_client_config current {}
data azurerm_subscription primary {}

# FIX: Required for Azure Cloud Shell (azurerm_client_config.current.object_id not populated)
# HACK: Retrieve user objectId in case it is not exposed in azurerm_client_config.current.object_id
data external account_info {
  program                      = [
                                 "az",
                                 "ad",
                                 "signed-in-user",
                                 "show",
                                 "--query",
                                 "{object_id:objectId}",
                                 "-o",
                                 "json",
                                 ]
  count                        = data.azurerm_client_config.current.object_id != null && data.azurerm_client_config.current.object_id != "" ? 0 : 1
}

data http localpublicip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
}

data http localpublicprefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${chomp(data.http.localpublicip.body)}"
}

# # Random password generator
# resource random_string password {
#   length                       = 12
#   upper                        = true
#   lower                        = true
#   number                       = true
#   special                      = true
# # override_special             = "!@#$%&*()-_=+[]{}<>:?" # default
# # Avoid characters that may cause shell scripts to break
#   override_special             = "!@#%*)(-_=+][]}{:?" 
# }

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

# These variables will be used throughout the Terraform templates
locals {
# password                     = ".Az9${random_string.password.result}"
  prefix                       = "storage-access"
  suffix                       = random_string.suffix.result
  repository                   = "azure-same-region-storage-access"
  resource_group_name          = "${lower(local.prefix)}-${terraform.workspace}-${lower(local.suffix)}"
  ipprefixdata                 = jsondecode(chomp(data.http.localpublicprefix.body))
  ipprefix                     = local.ipprefixdata.data.prefix
  admin_ip                     = [
                                  chomp(data.http.localpublicip.body) 
  ]
  admin_ips                    = setunion(local.admin_ip,var.admin_ips)
  admin_ip_ranges              = setunion([for ip in local.admin_ips : format("%s/30", ip)],var.admin_ip_ranges) # /32 not allowed in network_rules
  admin_cidr_ranges            = [for range in local.admin_ip_ranges : cidrsubnet(range,0,0)] # Make sure ranges have correct base address
  # FIX: Required for Azure Cloud Shell (azurerm_client_config.current.object_id not populated)
  automation_object_id         = data.azurerm_client_config.current.object_id != null && data.azurerm_client_config.current.object_id != "" ? data.azurerm_client_config.current.object_id : data.external.account_info.0.result.object_id

  tags                         = {
    application                = "Azure same-region storage access"
    provisioner                = "terraform"
    repository                 = local.repository
    suffix                     = local.suffix
    workspace                  = terraform.workspace
  }

  lifecycle                    = {
    ignore_changes             = ["tags"]
  }
}

resource azurerm_resource_group rg {
  name                         = local.resource_group_name
  location                     = var.location

  tags                         = local.tags
}

resource azurerm_log_analytics_workspace monitor {
  name                         = "${azurerm_resource_group.rg.name}-loganalytics"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  sku                          = "PerGB2018"
  retention_in_days            = 30

  tags                         = azurerm_resource_group.rg.tags
}