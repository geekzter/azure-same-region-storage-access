#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Deploys Azure resources using Terraform
 
.DESCRIPTION 
    This script is a wrapper around Terraform. It is provided for convenience only, as it works around some limitations in the demo. 
    E.g. terraform might need resources to be started before executing, and resources may not be accessible from the current locastion (IP address).

.EXAMPLE
    ./deploy.ps1 -apply
#> 
#Requires -Version 7.2

### Arguments
param ( 
    [parameter(Mandatory=$false,HelpMessage="Initialize Terraform backend, modules & provider")][switch]$Init=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform plan stage")][switch]$Plan=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform validate stage")][switch]$Validate=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform apply stage (implies plan)")][switch]$Apply=$false,
    [parameter(Mandatory=$false,HelpMessage="Validate storage access")][switch]$Test=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform destroy stage")][switch]$Destroy=$false,
    [parameter(Mandatory=$false,HelpMessage="Show Terraform output variables")][switch]$Output=$false,
    [parameter(Mandatory=$false,HelpMessage="Don't show prompts unless something get's deleted that should not be")][switch]$Force=$false,
    [parameter(Mandatory=$false,HelpMessage="Initialize Terraform backend, upgrade modules & provider")][switch]$Upgrade=$false,
    [parameter(Mandatory=$false,HelpMessage="Don't try to set up a Terraform backend if it does not exist")][switch]$NoBackend=$false,
    [parameter(Mandatory=$false,HelpMessage="Open Storage Firewall pre-plan")][switch]$OpenStorageFirewall=$false
) 

### Internal Functions
. (Join-Path $PSScriptRoot functions.ps1)

### Validation
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    $tfMissingMessage = "Terraform not found"
    if ($IsWindows) {
        $tfMissingMessage += "`nInstall Terraform e.g. from Chocolatey (https://chocolatey.org/packages/terraform) 'choco install terraform'"
    } else {
        $tfMissingMessage += "`nInstall Terraform e.g. using tfenv (https://github.com/tfutils/tfenv)"
    }
    throw $tfMissingMessage
}

Write-Information $MyInvocation.line 
$script:ErrorActionPreference = "Stop"

$workspace = Get-TerraformWorkspace
$planFile  = "${workspace}.tfplan".ToLower()
$varsFile  = "${workspace}.tfvars".ToLower()
$pipeline  = ![string]::IsNullOrEmpty($env:AGENT_VERSION)
$inAutomation = ($env:TF_IN_AUTOMATION -ieq "true")
if (($workspace -ieq "prod") -and $Force) {
    $Force = $false
    Write-Warning "Ignoring -Force in workspace '${workspace}'"
}

try {
    $tfdirectory = (Get-TerraformDirectory)
    Push-Location $tfdirectory
    AzLogin -DisplayMessages
    # Print version info
    terraform -version

    if ($Init -or $Upgrade) {
        if (!$NoBackend) {
            $backendFile = (Join-Path $tfdirectory backend.tf)
            $backendTemplate = "${backendFile}.sample"
            $newBackend = (!(Test-Path $backendFile))
            $tfbackendArgs = ""
            $env:TF_STATE_backend_storage_account_name   ??= $env:TF_STATE_BACKEND_STORAGE_ACCOUNT_NAME
            $env:TF_STATE_backend_storage_container_name ??= $env:TF_STATE_BACKEND_STORAGE_CONTAINER_NAME
            $env:TF_STATE_backend_resource_group_name    ??= $env:TF_STATE_BACKEND_RESOURCE_GROUP_NAME
            if ($newBackend) {
                if (!$env:TF_STATE_backend_storage_account_name -or !$env:TF_STATE_backend_storage_container_name) {
                    Write-Warning "Environment variables TF_STATE_backend_storage_account_name and TF_STATE_backend_storage_container_name must be set when creating a new backend from $backendTemplate"
                    $fail = $true
                }
                if (!($env:TF_STATE_backend_resource_group_name -or $env:ARM_ACCESS_KEY -or $env:ARM_SAS_TOKEN)) {
                    Write-Warning "Environment variables ARM_ACCESS_KEY or ARM_SAS_TOKEN or TF_STATE_backend_resource_group_name (with Terraform identity granted 'Storage Blob Data Contributor' role) must be set when creating a new backend from $backendTemplate"
                    $fail = $true
                }
                if ($fail) {
                    Write-Warning "This script assumes Terraform backend exists at ${backendFile}, but it does not exist"
                    Write-Host "You can copy ${backendTemplate} -> ${backendFile} and configure a storage account manually"
                    Write-Host "See documentation at https://www.terraform.io/docs/backends/types/azurerm.html"
                    exit
                }

                # Terraform azurerm backend does not exist, create one
                Write-Host "Creating '$backendFile'"
                Copy-Item -Path $backendTemplate -Destination $backendFile
                
                $tfbackendArgs += " -reconfigure"
            }

            if ($env:TF_STATE_backend_resource_group_name) {
                $tfbackendArgs += " -backend-config=`"resource_group_name=${env:TF_STATE_backend_resource_group_name}`""
            }
            if ($env:TF_STATE_backend_storage_account_name) {
                $tfbackendArgs += " -backend-config=`"storage_account_name=${env:TF_STATE_backend_storage_account_name}`""
            }
            if ($env:TF_STATE_backend_storage_container_name) {
                $tfbackendArgs += " -backend-config=`"container_name=${env:TF_STATE_backend_storage_container_name}`""
            }
        }

        $initCmd = "terraform init $tfbackendArgs"
        if ($Upgrade) {
            $initCmd += " -upgrade"
        }
        Invoke "$initCmd" 
    }

    if ($Validate) {
        Invoke "terraform validate" 
    }
    
    # Prepare common arguments
    if ($Force) {
        $forceArgs = "-auto-approve"
    }

    if (!(Get-ChildItem Env:TF_VAR_* -Exclude TF_STATE_backend_*) -and (Test-Path $varsFile)) {
        # Load variables from file, if it exists and environment variables have not been set
        $varArgs = " -var-file='$varsFile'"
    }

    if ($Plan -or $Apply -or $Destroy) {
        # Convert uppercased Terraform environment variables (Azure Pipeline Agent) to their original casing expected by Terraform
        foreach ($tfvar in $(Get-ChildItem -Path Env: -Recurse -Include TF_VAR_*)) {
            $prefix = (($tfvar.Name.Split("_")[0,1] | Select-Object -First 2) -Join "_")
            $properCaseName = $prefix + $tfvar.Name.Replace($prefix,"").ToLowerInvariant()
            Invoke-Expression "`$env:$properCaseName = `$env:$($tfvar.Name)"  
        } 

        $env:TF_VAR_location ??= Get-AzureRegion
        Write-Host "Using $env:TF_VAR_location as deployment target"

        if ($OpenStorageFirewall) {
            # ISSUE: If a pipeline agent, Codespace or VM is located in the same region as a storage account the request will be routed over Microsoft’s internal IPv6 network. As a result the source IP of the request is not the same as the one added to the Storage Account firewall.
            # 1.0;2020-05-17T13:22:59.2714021Z;GetContainerProperties;IpAuthorizationError;403;4;4;authenticated;xxxxxx;xxxxxx;blob;"https://xxxxxx.blob.core.windows.net:443/paasappscripts?restype=container";"/";75343457-f01e-005c-674e-2c705c000000;0;172.16.5.4:59722;2018-11-09;453;0;130;246;0;;;;;;"Go/go1.14.2 (amd64-linux) go-autorest/v14.0.0 tombuildsstuff/giovanni/v0.10.0 storage/2018-11-09";;
            # HACK: Open the door, Terraform will close it again
            # This will also cover the scenario when Terraform is run from multiple locations
            $terraformDirectory = (Join-Path (Split-Path -parent -Path $PSScriptRoot) "terraform")
            Push-Location $terraformDirectory
            $resourceGroup = (Get-TerraformOutput resource_group_name)
            $storageAccount = (Get-TerraformOutput storage_account_name)
            $subscriptionId = (Get-TerraformOutput subscription_id)
            Pop-Location

            if ($storageAccount) {
                Write-Host "`nOpening storage firewall on ${storageAccount}..."
                az storage account update -g $resourceGroup -n $storageAccount --default-action Allow --query "networkRuleSet" --subscription $subscriptionId #-o none
            } else {
                Write-Warning "No storage account found to open firewall on"
            }
        }
    }

    if ($Plan -or $Apply) {
        # Create plan
        Invoke "terraform plan $varArgs -out='$planFile'"
    }

    if ($Apply) {
        # Write-Host "Tainting storage firewall rules to get just-in-time deployment access..."
        # terraform state list | Select-String -Pattern "azurerm_storage_account_network_rules" | ForEach-Object {
        #     $resource = ($_ -replace "`"","`\`"")
        #     Invoke-Expression "terraform taint '$resource'"
        # }
        
        if (!$inAutomation) {
            if (!$Force) {
                # Prompt to continue
                Write-Host "`nIf you wish to proceed executing Terraform plan $planFile in workspace $workspace, please reply 'yes' - null or N aborts" -ForegroundColor Cyan
                $proceedanswer = Read-Host 

                if ($proceedanswer -ne "yes") {
                    Write-Host "`nReply is not 'yes' - Aborting " -ForegroundColor Yellow
                    exit
                }
            }
        }

        Invoke "terraform apply $forceArgs '$planFile'"
    }

    if ($Output) {
        Invoke "terraform output"
    }    

    if (($Apply -or $Output) -and $pipeline) {
        # Export Terraform output as Pipeline output variables for subsequent tasks
        Set-PipelineVariablesFromTerraform
    }    

    if ($Test) {
        $testScript = (Join-Path $PSScriptRoot "validate_storage_access.ps1")
        Write-Information "Invoking ${testScript}"
        & $testScript
    }

    if ($Destroy) {
        Invoke "terraform destroy $varArgs $forceArgs"
    }
} finally {
    Pop-Location
}