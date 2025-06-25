# Custom Script extension for Azure Arc enabled servers
# Custom script extension is a tool that can be used to automatically launch and execute machine customization tasks post configuration. When this Extension is added to an Azure Arc machine, it can download Powershell scripts and files from Azure storage and launch a Powershell script on the machine which in turn can download additional software components. Custom script extension tasks can also be automated using the Azure Powershell cmdlets.

$RGname = "arcbox-psconfeu-rg"
$MachineName = "ArcBox-Win2K25" # Windows
$Location = (Get-AzResourceGroup -Name $RGName).Location

# Example: Deploy Custom Script Extension on Azure Arc-enabled Server
# This extension downloads and executes scripts for post-deployment configuration
$ExtensionName = "CustomScriptExtension"
$Publisher = "Microsoft.Compute"
$ExtensionType = "CustomScriptExtension"  # Windows
# $ExtensionType = "CustomScript"         # Linux (Microsoft.Azure.Extensions)

# Deploy Custom Script Extension with inline script
New-AzConnectedMachineExtension `
    -ResourceGroupName $RGname `
    -MachineName $MachineName `
    -Name $ExtensionName `
    -Location $Location `
    -Publisher $Publisher `
    -ExtensionType $ExtensionType `
    -Setting @{
        'commandToExecute' = 'powershell.exe -ExecutionPolicy Unrestricted -Command "Write-Output \"Hello from Custom Script Extension!\"; Get-Process | Select-Object -First 5 | Out-File C:\extension-output.txt"'
    }

# Alternative: Deploy extension with script from storage
<#
$StorageAccountName = "mystorageaccount"
$ScriptUri = "https://$StorageAccountName.blob.core.windows.net/scripts/setup-script.ps1"
$SasToken = "?sv=2021-06-08&ss=b&srt=sco&sp=r&se=2025-12-31T23:59:59Z&st=2025-01-01T00:00:00Z&spr=https&sig=..."

New-AzConnectedMachineExtension `
    -ResourceGroupName $RGname `
    -MachineName $MachineName `
    -Name $ExtensionName `
    -Location $Location `
    -Publisher $Publisher `
    -ExtensionType $ExtensionType `
    -Setting @{
        'fileUris' = @($ScriptUri)
        'commandToExecute' = 'powershell.exe -ExecutionPolicy Unrestricted -File setup-script.ps1'
    } `
    -ProtectedSetting @{
        'storageAccountName' = $StorageAccountName
        'storageAccountKey' = 'your-storage-account-key'
    }
#>

# Check extension status
Get-AzConnectedMachineExtension -ResourceGroupName $RGname -MachineName $MachineName -Name $ExtensionName

# Remove extension when no longer needed
# Remove-AzConnectedMachineExtension -ResourceGroupName $RGname -MachineName $MachineName -Name $ExtensionName

# Key limitation: New-AzConnectedMachineExtension - CustomScriptExtension is already installed on ResourceId: ArcBox-Win2K25. Only one Extension of this type is permitted.


<#

Run Command on Azure Arc-enabled Servers (Preview)
==================================================

The Run command feature allows you to remotely and securely execute scripts or commands on
Arc-enabled virtual machines without connecting directly through RDP or SSH. This capability
is built into the Connected Machine agent and provides centralized script management across
creation, update, deletion, sequencing, and listing operations.

Key Features:
• Remote Execution - Execute scripts without direct RDP/SSH access
• Cross-Platform Support - Works on both Windows and Linux Arc-enabled servers
• Multiple Interfaces - Available via Azure CLI, PowerShell, and REST API
• Security Enhanced - Helps apply security patches, enforce compliance, and remediate vulnerabilities
• Centralized Management - Built-in script lifecycle management (create, update, delete, list)
• No Additional Extensions - Uses existing Connected Machine agent (v1.33+)
• Cost Effective - Run command is free; only storage for scripts incurs charges
• RBAC Integration - Role-based access control for command execution permissions
• Hybrid Ready - Works across on-premises, multi-cloud (AWS, GCP), and edge environments
• Output Management - Captures execution results with support for blob storage output

Use Cases:
• Security patch deployment and compliance enforcement
• Software installation and configuration management
• Health checks and troubleshooting across hybrid infrastructure
• Automated administrative tasks without individual server access
• Password rotation and security policy enforcement

Prerequisites: Connected Machine agent version 1.33 or higher

Source: https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command

#>

# Documentation
Start-Process https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command

# Azure CLI

az login
az extension add --name connectedmachine

$RGname = "arcbox-psconfeu-rg"
$MachineName = "ArcBox-Win2K25"
$Location = (Get-AzResourceGroup -Name $RGName).Location

<#
RunCommand Create:
az connectedmachine run-command create -g <resource-group> --machine-name <machine-name> -n <runcommand-name> --script "Write-Host 'Hello World'" --location <centraluseuap/eastus2euap>
#>

az connectedmachine run-command create -g $RGname --machine-name $MachineName -n demo1 --script "Write-Host 'Hello World'" --location westeurope

az connectedmachine run-command create -g $RGname --machine-name $MachineName -n demo1 --script "Restart-Service spooler -PassThru" --location westeurope --no-wait

az connectedmachine run-command create -g $RGname --machine-name $MachineName -n demo1 --script "Write-Host 'Hello World'" --location westeurope

az connectedmachine run-command create --help

# --command-id                            : Specifies the commandId of predefined built-in script.
# --script-uri
#  --script-uri-managed-identity           : User-assigned managed identity that has access to scriptUri in case of Azure storage blob.


<#
RunCommand Get:
az connectedmachine run-command show -g <resource-group> --machine-name <machine-name> -n <runcommand-name>
#>

az connectedmachine run-command show -g $RGname --machine-name $MachineName -n demo1
az connectedmachine run-command show -g $RGname --machine-name $MachineName -n demo1 | ConvertFrom-Json | Select-Object -ExpandProperty InstanceView

az connectedmachine run-command show -g $RGname --machine-name $MachineName -n demo2

az connectedmachine run-command show -g $RGname --machine-name $MachineName -n demo1

<#
RunCommand List:
az connectedmachine run-command list -g <resource-group> --machine-name <machine-name>
#>

az connectedmachine run-command list -g $RGname --machine-name $MachineName

az connectedmachine run-command list -g $RGname --machine-name $MachineName

<#
RunCommand Delete:
az connectedmachine run-command delete -g <resource-group> --machine-name <machine-name> -n <runcommand-name>
#>

az connectedmachine run-command delete -g $RGname --machine-name $MachineName -n demo1



# Azure PowerShell

Connect-AzAccount

Install-Module Az.ConnectedMachine -RequiredVersion 1.1.1

Import-Module Az.ConnectedMachine -PassThru

# New-AzConnectedMachineRunCommand -ResourceGroupName "<Resource Group Name>" -Location "<Location>" -SourceScript "ifconfig" -RunCommandName "<Identifying Name of command>" -MachineName "<Machine Name>"

$RGname = "arcbox-psconfeu-rg"
$MachineName = "ArcBox-Win2K25" # Windows
$Location = (Get-AzResourceGroup -Name $RGName).Location

# Run Command on Windows Arc-enabled Server

New-AzConnectedMachineRunCommand -MachineName $MachineName -SourceScript "Get-Process | Sort-Object CPU -desc | Select-Object -First 5" -RunCommandName "ProcInfo" -AsJob -ResourceGroupName $RGname -Location $Location

Get-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname | Select-Object Name,SourceScript,ProvisioningState,InstanceViewExecutionState

Get-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname -RunCommandName "ProcInfo"

Get-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname -RunCommandName "ProcInfo" | Select-Object -ExpandProperty InstanceViewOutput

Remove-AzConnectedMachineRunCommand -ResourceGroupName $RGname -RunCommandName "ProcInfo" -MachineName $MachineName -AsJob

# Run Command on Linux Arc-enabled Server

$MachineName = "ArcBox-Ubuntu-01" # Linux
New-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname -Location $Location -SourceScript "ps" -RunCommandName "ProcInfo" -AsJob

Get-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname  | Select-Object Name,SourceScript,ProvisioningState,InstanceViewExecutionState

Get-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname -RunCommandName "ProcInfoDemo"  | Select-Object -ExpandProperty InstanceViewOutput

Remove-AzConnectedMachineRunCommand -MachineName $MachineName -ResourceGroupName $RGname -RunCommandName "ProcInfo"  -AsJob

<#
    Run from source script in blob storage and redirect output to blob
    New-AzConnectedMachineRunCommand -ResourceGroupName -MachineName -RunCommandName -ScriptUriManagedIdentityObjectId <xxx> -SourceScriptUri “<URI of a storage blob with read access or public URI>” -OutputBlobUri “<URI of a storage append blob with read, add, create, write access>”

    Output limits:
    Both Custom Script Extension and Run Command have the same 4 KB limit, but Run command provides a better solution for handling large outputs through blob storage integration, whereas Custom Script Extension has no workaround for the 4 KB limitation.

    Additional relevant parameters:

    -AsJob
        Run the command in the background and return a job object. The job can be used to check the status of the command and retrieve the output.

    -AsyncExecution
        Provisioning will complete as soon as script starts and will not wait for it to complete.

    -NoWait
        Run the command asynchronously and return immediately without waiting for the command to complete.


Run Command vs Custom Script Extension Comparison
================================================

| Feature | Run Command (Arc-enabled Servers) | Custom Script Extension |
|---------|-----------------------------------|-------------------------|
| **Purpose** | Remote execution without direct access | Post-deployment configuration and automation |
| **Execution Model** | On-demand script execution | Extension-based deployment |
| **Installation** | Built into Connected Machine agent | Requires VM extension installation |
| **Access Method** | Azure CLI, PowerShell, REST API | Azure CLI, PowerShell, ARM templates, Portal |
| **Script Storage** | Inline or blob storage with SAS URI | Azure Storage, GitHub, or inline |
| **Prerequisites** | Connected Machine agent v1.33+ | VM extension framework |
| **Execution Frequency** | Multiple executions supported | Single execution per extension instance |
| **State Management** | Centralized lifecycle (create/update/delete) | Extension-based state management |
| **Cost** | Free (storage charges only) | Free (storage charges only) |
| **Output Handling** | Built-in capture with blob storage support | Manual output handling required |
| **Network Requirements** | Azure connectivity through Arc agent | Azure connectivity or internet access |
| **Use Case** | Administrative tasks, troubleshooting, security | Software installation, VM configuration |
| **Script Languages** | PowerShell (Windows), Bash (Linux) | PowerShell (Windows), Bash (Linux) |
| **Update Mechanism** | Create new or update existing run command | Remove and redeploy extension |
| **Monitoring** | Built-in execution status and progress | Extension status monitoring |

Key Differences:
• Run Command is designed for operational tasks and remote management
• Custom Script Extension is optimized for deployment-time configuration

Sources:
- https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command
- https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows
- https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux

#>

# Block or allow the execution of scripts on Azure Arc-enabled servers

azcmagent config set extensions.allowlist "microsoft.cplat.core/runcommandhandlerwindows"
azcmagent config set extensions.allowlist "microsoft.cplat.core/runcommandhandlerlinux"

azcmagent config set extensions.blocklist "microsoft.cplat.core/runcommandhandlerwindows"
azcmagent config set extensions.blocklist "microsoft.cplat.core/runcommandhandlerlinux"

# Learn more about azcmagent config set extensions.allowlist and azcmagent config set extensions.blocklist:
Start-Process 'https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command-security'