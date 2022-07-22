data azurerm_client_config current {}
data azurerm_subscription primary {}

data http local_public_ip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
}

data http local_public_prefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${chomp(data.http.local_public_ip.body)}"
}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  numeric                      = false
  special                      = false
}

# These variables will be used throughout the Terraform templates
locals {
  owner                        = var.application_owner != "" ? var.application_owner : data.azurerm_client_config.current.object_id
# password                     = ".Az9${random_string.password.result}"
  suffix                       = var.resource_suffix != "" ? lower(var.resource_suffix) : random_string.suffix.result
  repository                   = "azure-same-region-storage-access"
  resource_group_name          = "${lower(var.resource_prefix)}-${terraform.workspace}-${lower(local.suffix)}"
  ip_prefix_data               = jsondecode(chomp(data.http.local_public_prefix.body))
  ip_prefix                    = local.ip_prefix_data.data.prefix

  tags                         = {
    application                = var.application_name
    owner                      = local.owner
    provisioner                = "terraform"
    provisioner-client-id      = data.azurerm_client_config.current.client_id
    provisioner-object-id      = data.azurerm_client_config.current.object_id
    repository                 = local.repository
    runid                      = var.run_id
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