#!/usr/bin/env pwsh

. (Join-Path $PSScriptRoot functions.ps1)

$location = Get-AzureRegion

if ($location) {
    Write-Host "Azure region is '$location'"
} else {
    Write-Host "VM metadata endpoint not found, it appears you are not running in Azure."
}

Write-Host "`nOther location info:"
Invoke-RestMethod https://ipinfo.io/json | Format-List