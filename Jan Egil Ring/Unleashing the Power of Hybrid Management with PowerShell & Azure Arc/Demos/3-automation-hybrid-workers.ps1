<#
Azure Automation Hybrid Runbook Workers on Arc-enabled Servers
==============================================================

Overview:
---------
Azure Automation provides native integration of the Hybrid Runbook Worker role through the Azure VM extension framework.
Arc-enabled servers can serve as Hybrid Runbook Workers, enabling runbooks to run directly on machines in your environment
to manage local resources and bridge cloud-based automation with on-premises infrastructure.

Key Features:
- Extension-based deployment (recommended V2 platform)
- No dependency on Log Analytics agent
- Direct execution on Arc-enabled servers
- Secure authentication using managed identities
- Centralized management from Azure Automation

Architecture:
- Azure Connected Machine agent manages the Hybrid Runbook Worker extension
- Runbooks stored and managed in Azure Automation
- Jobs delivered to assigned machines in your environment
- Consistent management experience for hybrid resources

Use Cases for Arc-enabled Servers as Hybrid Runbook Workers:
------------------------------------------------------------

1. At-Scale Operations:
   - Deploy and manage infrastructure across multiple environments
   - Execute maintenance tasks on schedules (start/stop services, cleanup operations)

2. Automated Remediation via Azure Monitor Integration:
   - Respond to Azure Monitor alerts with automated remediation
   - Self-healing operations triggered by alert conditions
   - Escalate issues to ITSM systems when automation cannot resolve
   - Proactive monitoring and response for hybrid environments

3. On-Premises Active Directory Management:
   - User account provisioning and deprovisioning
   - Group membership management
   - Password policy enforcement
   - Audit and compliance reporting
   - Domain controller maintenance tasks

4. SQL Server Management:
   - Database backup and maintenance operations
   - Performance monitoring and optimization
   - Index maintenance and statistics updates
   - User access management
   - Compliance auditing and reporting

5. Application Lifecycle Management:
   - Service restart and health checks
   - Configuration file management
   - Log collection and analysis

Integration Scenarios:
---------------------

Azure Monitor Action Groups → Automation Runbooks:
When Azure Monitor detects issues (high CPU, disk space, service failures),
action groups can trigger Automation runbooks on Hybrid Workers to:
- Investigate and resolve the issue
- Collect diagnostic information
- Perform corrective actions
- Create ITSM tickets if manual intervention needed

Benefits of Extension-Based Hybrid Workers:
-------------------------------------------
- Simplified deployment and management
- Better security with managed identities
- No Log Analytics workspace dependency
- Consistent with Azure VM extension framework
- Future-proof architecture (Agent-based V1 retiring April 2025)

Authentication and Security:
- Uses system-assigned or user-assigned managed identities
- Secure communication with Azure Automation
- Role-based access control (RBAC) integration
- No credentials stored in runbook code

Deployment Process:
1. Install HybridWorkerForWindows or HybridWorkerForLinux extension
2. Configure Hybrid Worker Groups in Azure Automation
3. Assign runbooks to specific worker groups
4. Monitor execution through Azure portal

Common PowerShell Modules for Hybrid Operations:
- ActiveDirectory (for AD management)
- SqlServer (for SQL operations)
- Custom modules for specific applications

#>

# PowerShell example: Deploy Hybrid Runbook Worker extension to Arc-enabled servers

# Connect to Azure
Connect-AzAccount

# Define variables
$ResourceGroupName = "arcbox-psconfeu-rg"
$AutomationAccountName = "psconfeu-aa"
$HybridWorkerGroupName = "OnPremWorkers"

# Get Arc-enabled servers in the resource group
$ArcServers = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName

# Install Hybrid Runbook Worker extension on Windows Arc-enabled servers
foreach ($Server in $ArcServers | Where-Object {$_.OSName -like "*Windows*"}) {
    Write-Output "Installing Hybrid Worker extension on $($Server.Name)"

    $ExtensionParams = @{
        ResourceGroupName = $ResourceGroupName
        MachineName = $Server.Name
        Name = "HybridWorker"
        Publisher = "Microsoft.Compute"
        ExtensionType = "HybridWorkerForWindows"
        Settings = @{
            AutomationAccountURL = "https://$($Server.Location).automation.azure.com"
        }
    }

    try {
        New-AzConnectedMachineExtension @ExtensionParams
        Write-Output "✓ Extension installed successfully on $($Server.Name)"
    }
    catch {
        Write-Error "Failed to install extension on $($Server.Name): $($_.Exception.Message)"
    }
}

# Example: Create a Hybrid Worker Group and add machines
New-AzAutomationHybridWorkerGroup -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $HybridWorkerGroupName

# Example runbook for automated remediation triggered by Azure Monitor alert
<#
Runbook: Invoke-DiskSpaceRemediation
Purpose: Responds to disk space alerts by performing cleanup operations
Triggered by: Azure Monitor Action Group when disk space exceeds threshold
#>

#[OutputType("PSAzureOperationResponse")]
param
(
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)
$ErrorActionPreference = "stop"

if ($WebhookData)
{
    # Get the data object from WebhookData
    $WebhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

# Get the info needed to identify the VM (depends on the payload schema)
    $schemaId = $WebhookBody.schemaId
    Write-Verbose "schemaId: $schemaId" -Verbose
    if ($schemaId -eq "azureMonitorCommonAlertSchema") {
        # This is the common Metric Alert schema (released March 2019)
        $Essentials = [object] ($WebhookBody.data).essentials
        # Get the first target only as this script doesn't handle multiple
        $alertTargetIdArray = (($Essentials.alertTargetIds)[0]).Split("/")
        $SubId = ($alertTargetIdArray)[2]
        $ResourceGroupName = ($alertTargetIdArray)[4]
        $ResourceType = ($alertTargetIdArray)[6] + "/" + ($alertTargetIdArray)[7]
        $ResourceName = ($alertTargetIdArray)[-1]
        $status = $Essentials.monitorCondition
    }
    elseif ($schemaId -eq "AzureMonitorMetricAlert") {
        # This is the near-real-time Metric Alert schema
        $AlertContext = [object] ($WebhookBody.data).context
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = $AlertContext.resourceName
        $status = ($WebhookBody.data).status
    }
    elseif ($schemaId -eq "Microsoft.Insights/activityLogs") {
        # This is the Activity Log Alert schema
        $AlertContext = [object] (($WebhookBody.data).context).activityLog
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = (($AlertContext.resourceId).Split("/"))[-1]
        $status = ($WebhookBody.data).status
    }
    elseif ( $null -eq $schemaId) {
        # This is the original Metric Alert schema
        $AlertContext = [object] $WebhookBody.context
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = $AlertContext.resourceName
        $status = $WebhookBody.status
    }
    else {
        # Schema not supported
        Write-Error "The alert data schema - $schemaId - is not supported."
    }

Write-Verbose "status: $status" -Verbose
    if (($status -eq "Activated") -or ($status -eq "Fired"))
    {
        Write-Verbose "resourceType: $ResourceType" -Verbose
        Write-Verbose "resourceName: $ResourceName" -Verbose
        Write-Verbose "resourceGroupName: $ResourceGroupName" -Verbose
        Write-Verbose "subscriptionId: $SubId" -Verbose

# Determine code path depending on the resourceType
        if ($ResourceType -eq "Microsoft.Compute/virtualMachines")
        {
            # This is an Resource Manager VM
            Write-Verbose "This is an Resource Manager VM." -Verbose

# Ensures you do not inherit an AzContext in your runbook
            Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
            $AzureContext = (Connect-AzAccount -Identity).context

# set and store context
            $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# This isn`t a complete example, but the below code is typically something which could triggered as a Run Command script on the VM as an alternative to connect directly to the VM from the runbook.

            if ($IsWindows) {

                Write-Output 'Free disk space before cleanup action'
                Get-Volume -DriveLetter C | Out-String

                Write-Output "Windows Update component store cleanup"
                Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

                $SystemTemp = "$env:SystemRoot\Temp"
                Write-Output "Empty the system temporary folder: $SystemTemp"

                Get-ChildItem -Path $SystemTemp -Recurse | Remove-Item -Force -Recurse

                Write-Output 'Free disk space after cleanup action'
                Get-Volume -DriveLetter C | Out-String

            } elseif ($IsLinux) {

                Write-Output 'Free disk space before cleanup action'
                df -h -m

                # Specify the directory where your log files are located
                $logDir = '/var/log'

                # Define the number of days to retain log files
                $daysToKeep = 7

                # Get the current date
                $currentDate = Get-Date

                # Calculate the date threshold for log file deletion
                $thresholdDate = $currentDate.AddDays(-$daysToKeep)

                # List log files in the specified directory that are older than the threshold
                $filesToDelete = Get-ChildItem -Path $logDir -File | Where-Object { $_.LastWriteTime -lt $thresholdDate }

                # Delete the old log files
                foreach ($file in $filesToDelete) {
                    Remove-Item -Path $file.FullName -Force
                }

                Write-Output 'Free disk space after cleanup action'
                df -h -m

            }


        }
        else {
            # ResourceType not supported
            Write-Error "$ResourceType is not a supported resource type for this runbook."
        }
    }
    else {
        # The alert status was not 'Activated' or 'Fired' so no action taken
        Write-Verbose ("No action taken. Alert status: " + $status) -Verbose
    }
}
else {
    # Error
    Write-Error "This runbook is meant to be started from an Azure alert webhook only."
}

