variable address_space {
  default                      = "10.16.0.0/12"
}

variable location {
  description                  = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  # These are examples of regions that support all features:
  # eastus, northeurope, southeastasia, uksouth, westeurope, westus2
  default                      = "northeurope"
}

variable resource_prefix {
  description                  = "The prefix to put in front of resource names created"
  default                      = "storage-access"
}
variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = "" # Empty string triggers a random suffix
}
variable run_id {
  description                  = "The ID that identifies the pipeline / workflow that invoked Terraform"
  default                      = ""
}