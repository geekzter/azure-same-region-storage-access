#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Tests access to storage by attempting a blob download
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

$tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
Push-Location $tfdirectory

try {    
    $storageUrl = (Get-TerraformOutput storage_url)  
    Write-Debug "storageUrl: $storageUrl"
    $storageSas = (Get-TerraformOutput storage_sas)  
    Write-Debug "storageSas: $storageSas"

    Write-Debug "az storage container list --blob-endpoint `"$storageUrl`" --sas-token `"$storageSas`""
    az storage container list --blob-endpoint "$storageUrl" --sas-token "$storageSas"
} finally {
    Pop-Location
}