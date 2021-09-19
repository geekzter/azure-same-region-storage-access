variable admin_ip_ranges {
  default                      = []
}
variable admin_ips {
  default                      = []
}

variable address_space {
  default                      = "10.16.0.0/12"
}

variable location {
  description                  = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  # These are examples of regions that support all features:
  # eastus, northeurope, southeastasia, uksouth, westeurope, westus2
  default                      = "northeurope"
}