# Azure Storage same region access
 
## Private IP space
- Azure Storage uses private IP space when the client is [in the same region](https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#grant-access-from-an-internet-ip-range) even when Private Endpoints are not used. The client IP address as seen by the Storage Firewall is a private IP address that cannot be predicted. Hence Storage Firewall can't be used to allow/block access over the public endpoint
- Terraform will need storage data plane read access during plan stage, hence any dependency tricks during apply stage will not work

## Demonstrating the issue
- Run [deploy.ps1](./scripts/deploy.ps1) with the `-SkipFirewallUpdate` parameter. This script will detect the region it is run from using the Azure Instance Metadata and deploy to the same region by setting the `TF_VAR_location` environment variable.
- Run [terraform-ci.yml](./pipelines/terraform-ci.yml) with the 'Open Storage Firewall as needed' (`letMeIn`) parameter disabled, this relies on [deploy.ps1](./scripts/deploy.ps1) and therefore works the same way

## Workaround
- This repo works around the issue by opening up the Storage Firewall prior to Terraform plan stage. This is done using a default allow rule as the client IP address as seen by the Storage Firewall cannot be known.
- Terraform `depends_on` on `azurerm_storage_account_network_rules` resources ensure the Storage Firewall is updated after any required data plane access has been performed