#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Tests access to storage by attempting a blob download
#> 
#Requires -Version 7

param ( 
    [parameter(Mandatory=$false)][int]$MaxTests=60
) 

. (Join-Path $PSScriptRoot functions.ps1)

$tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
Push-Location $tfdirectory

try {    
    $blobUrl = (Get-TerraformOutput storage_blob_url)  
    if (!$blobUrl) {
        Write-Warning "Azure Storage blob not found, has infrastructure been provisioned?"
        exit
    }

    # Invoke-WebRequest $blobUrl
    Test-Url -Url $blobUrl -MaxTests $MaxTests
} finally {
    Pop-Location
}