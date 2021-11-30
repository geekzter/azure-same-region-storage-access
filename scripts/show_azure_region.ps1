#!/usr/bin/env pwsh

. (Join-Path $PSScriptRoot functions.ps1)

$location = Get-AzureRegion

if ($location) {
    Write-Host "Azure region is '$location'"
} else {
    Write-Host "Not running in Azure"
}