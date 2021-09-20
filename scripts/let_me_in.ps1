#!/usr/bin/env pwsh

#Requires -Version 7

### Internal Functions
. (Join-Path $PSScriptRoot functions.ps1)

# ISSUE: If a pipeline agent or Codespace is located in the same region as a storage account the request will be routed over Microsoft’s internal IPv6 network. As a result the source IP of the request is not the same as the one added to the Storage Account firewall.
# 1.0;2020-05-17T13:22:59.2714021Z;GetContainerProperties;IpAuthorizationError;403;4;4;authenticated;xxxxxx;xxxxxx;blob;"https://xxxxxx.blob.core.windows.net:443/paasappscripts?restype=container";"/";75343457-f01e-005c-674e-2c705c000000;0;172.16.5.4:59722;2018-11-09;453;0;130;246;0;;;;;;"Go/go1.14.2 (amd64-linux) go-autorest/v14.0.0 tombuildsstuff/giovanni/v0.10.0 storage/2018-11-09";;
# HACK: Open the door, Terraform will close it again
# This will also cover the scenario when Terraform is run from multiple locations
$terraformDirectory = (Join-Path (Split-Path -parent -Path $PSScriptRoot) "terraform")
Push-Location $terraformDirectory
$resourceGroup = (Get-TerraformOutput resource_group_name)
$storageAccount = (Get-TerraformOutput storage_account_name)
Pop-Location

if ($storageAccount) {
    Write-Host "Opening storage firewall on ${storageAccount}..."
    az storage account update -g $resourceGroup -n $storageAccount --default-action Allow --query "networkRuleSet" #-o none
}