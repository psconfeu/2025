# SSH access to Azure Arc-enabled servers

<#

SSH Access to Azure Arc-enabled Servers Overview
===============================================

SSH access via Azure Arc enables secure remote connections to Arc-enabled servers WITHOUT requiring:
• Public IP addresses
• Open SSH ports in firewalls
• VPN connections
• Direct network line-of-sight

This capability leverages the Azure Arc connectivity platform to provide secure, audited access
to both Windows and Linux machines across hybrid, multi-cloud, and edge environments.

Key Benefits:
• 🔒 Enhanced Security - No exposed SSH ports or public IPs required
• 🌐 Hybrid Access - Works across on-premises, AWS, GCP, VMware, and other environments
• 🆔 Entra Integration - Use Microsoft Entra ID for authentication (Linux)
• 📋 RBAC Control - Fine-grained access control using Azure roles
• 📊 Auditing - All access is logged and auditable through Azure
• 🛠️ Tool Integration - Works with existing SSH-based tools and automation

Authentication Methods:
1. Local Credentials - Traditional SSH keys or username/password
2. Microsoft Entra ID - authentication with temporary local accounts

Required Azure Roles for Access:
• Virtual Machine Local User Login - SSH with local credentials
• Virtual Machine User Login - SSH with Entra ID (standard user)
• Virtual Machine Administrator Login - SSH with Entra ID (admin privileges)

Prerequisites:
• Connected Machine agent v1.31 or higher
• SSH service (sshd) enabled on target machine
• Owner or Contributor role on the Arc-enabled server
• Azure CLI ssh extension or Az.Ssh PowerShell module

Architecture:
Client → Azure Arc Connectivity Service → Connected Machine Agent → Target Server

Security Features:
• Web socket-based secure tunneling
• Role-based privilege assignment (user vs admin)
• Local agent controls to disable remote access
• Integration with Azure Privileged Identity Management (PIM)

Source: https://learn.microsoft.com/azure/azure-arc/servers/ssh-arc-overview

#>

# Documentation
Start-Process 'https://learn.microsoft.com/azure/azure-arc/servers/ssh-arc-overview'

# Azure Portal integration
Start-Process 'https://portal.azure.com/#@nicarcmasterclass.cloud/resource/subscriptions/5d743864-3e9e-4dc1-b446-1982647eeaf8/resourceGroups/arcbox-psconfeu-rg/providers/Microsoft.HybridCompute/machines/ArcBox-Win2K25/connect'

#region Prerequisites

    # Azure CLI extension
    az extension add --name ssh

    # Verify the installation
    az extension list --output table

    # Azure PowerShell modules
    Install-PSResource -Name Az.Ssh -TrustRepository
    Install-PSResource -Name Az.Ssh.ArcProxy -TrustRepository

    # Verify the installation
    Get-Module -ListAvailable -Name Az.Ssh*

    # On the Arc-enabled Windows Servers, install the OpenSSH Server feature
    # - On Windows Server 2025, this feature is installed by default but needs to be configured

    # Verify the status of the sshd service
    Get-Service sshd

    # If not present and running:

    # Install the OpenSSH Server (installed by default in Windows Server 2025)
    # If the OpenSSH Server feature is not installed, run the following command:
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Start the sshd service
    Start-Service sshd

    # Configure the service to start automatically
    Set-Service -Name sshd -StartupType 'Automatic'

    # Confirm the Windows Firewall is configured to allow SSH. The rule should be created automatically by setup. Run the following to verify:
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule "OpenSSH-Server-In-TCP" does not exist, creating it..."
        New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }

    # Similarly for Linux, ensure the SSH service is installed and running:
    # On Linux, the SSH service is typically installed by default. You can check its status with:
    systemctl status sshd

#endregion

# Authenticate

# Azure CLI
az login

# Show current context
az account show --output table

# Azure PowerShell
Connect-AzAccount

Get-AzContext

$resourceGroup = "arcbox-psconfeu-rg"
$azureLocation = (Get-AzResourceGroup -Name $RGName).Location

#region Windows

$serverName = "ArcBox-Win2K25"
$localUser = "Administrator" # or any other local user or Active Directory user

az ssh arc --resource-group $resourceGroup --name $serverName --local-user $localUser

Enter-AzVM -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser

# Remote Desktop Protocol (RDP)
$serverName = "ArcBox-Win2K25"
$localUser = "Administrator"

Set-Clipboard -Value 'JS123!!'

az ssh arc --resource-group $resourceGroup --name $serverName --local-user $localUser --rdp

Enter-AzVM -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser -Rdp

# To see the dynamic port used by the RDP connection, you can use the following command in PowerShell (while the previous RDP session is active):
Get-NetTCPConnection -OwningProcess (Get-Process mstsc).Id

#endregion

#region Linux

$serverName = "ArcBox-Ubuntu-01"
$localUser = "jumpstart"

# Local user
az ssh arc --resource-group $resourceGroup --name $serverName --local-user $localUser

Enter-AzVM -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser

# SSH key authentication example (the public key is already set up on the remote server)
$serverName = "ArcBox-Ubuntu-02"
Enter-AzVM -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser

# Entra ID authentication

# Takes 3-4 minutes to complete, already installed on the Arc-enabled Linux server in this demo

# Azure CLI
az connectedmachine extension create --machine-name $serverName --resource-group $resourceGroup --publisher Microsoft.Azure.ActiveDirectory --name AADSSHLogin --type AADSSHLoginForLinux --location $azureLocation

# Azure PowerShell

New-AzConnectedMachineExtension `
    -MachineName $serverName `
    -ResourceGroupName $resourceGroup `
    -Publisher "Microsoft.Azure.ActiveDirectory" `
    -Name "AADSSHLogin" `
    -ExtensionType "AADSSHLoginForLinux" `
    -Location $azureLocation

$User = Get-AzAdUser -Mail (Get-AzContext).Account.Id
$Scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroup/providers/Microsoft.HybridCompute/machines/$serverName"

# Azure CLI
az role assignment create --role "Virtual Machine Administrator Login" --assignee $User.Id --scope $Scope

# Azure PowerShell
New-AzRoleAssignment -ObjectId $User.Id -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $Scope

# Inspect the extension and RBAC assignment in the Azure Portal
Start-Process 'https://portal.azure.com/#@nicarcmasterclass.cloud/resource/subscriptions/5d743864-3e9e-4dc1-b446-1982647eeaf8/resourceGroups/arcbox-psconfeu-rg/providers/Microsoft.HybridCompute/machines/Arcbox-Ubuntu-02/extensions'

# Now let us try without the local user parameter, using Entra ID authentication

az ssh arc --resource-group $resourceGroup --name $serverName

Enter-AzVM -ResourceGroupName $resourceGroup -Name $serverName

# PowerShell Remoting via SSH
# https://learn.microsoft.com/azure/azure-arc/servers/ssh-arc-powershell-remoting

<#

PowerShell Remoting via SSH for Azure Arc-enabled Servers
=========================================================

PowerShell remoting over SSH provides a powerful way to manage Arc-enabled servers using familiar
PowerShell cmdlets and sessions, leveraging the secure SSH connectivity through Azure Arc.

Key Benefits:
• 🔄 Native PowerShell Experience - Use familiar remoting cmdlets (New-PSSession, Invoke-Command, Enter-PSSession)
• 🔒 Secure Connectivity - Leverages Azure Arc SSH tunneling (no open ports or public IPs)
• 🌐 Cross-Platform - Works with Windows PowerShell, PowerShell Core, and Linux targets
• 📋 Session Management - Create persistent sessions for multiple operations
• 🚀 Bulk Operations - Execute commands across multiple Arc-enabled servers simultaneously
• 📄 Script Execution - Run local scripts on remote Arc-enabled servers

Prerequisites:
• SSH access to Azure Arc-enabled servers configured
• PowerShell remoting over SSH requirements met
• Az.Ssh PowerShell module installed on client machine
• SSH service configured on target servers

Core PowerShell Remoting Cmdlets:
• New-PSSession - Create persistent PowerShell sessions
• Enter-PSSession - Interactive remote PowerShell session
• Invoke-Command - Execute commands/scripts on remote sessions
• Get-PSSession - List active PowerShell sessions
• Remove-PSSession - Clean up and close sessions

Workflow Overview:
1. Export SSH configuration using Export-AzSshConfig
2. Extract ProxyCommand from SSH config for tunnel setup
3. Create PSSession using SSH proxy command
4. Execute commands or scripts via Invoke-Command
5. Manage interactive sessions with Enter-PSSession
6. Clean up sessions when complete

Security Features:
• Authentication through Azure Arc SSH (local or Entra ID)
• Encrypted PowerShell remoting over SSH tunnel
• Session isolation and proper cleanup
• Audit trail through Azure Arc connectivity logs

Use Cases:
• Configuration management across hybrid infrastructure
• Bulk administrative tasks on multiple servers
• Interactive troubleshooting and diagnostics
• Automated script deployment and execution
• Cross-platform PowerShell operations

Example Session Management:
$sessions = New-PSSession -HostName server1,server2 -UserName admin -Options $proxyOptions
Invoke-Command -Session $sessions -ScriptBlock { Get-Service | Where Status -eq 'Running' }
Get-PSSession | Remove-PSSession

This enables enterprise-scale PowerShell management across hybrid environments through Azure Arc!

#>

Start-Process 'https://learn.microsoft.com/azure/azure-arc/servers/ssh-arc-powershell-remoting'

Set-Clipboard -Value 'JS123!!'

$Machines = Get-AzConnectedMachine -ResourceGroupName $resourceGroup | Where-Object Status -eq "Connected" #| where name -like "ArcBox-SQL*"
$sessions = @()

foreach ($Machine in $Machines) {

    $serverName = $Machine.Name
    $resourceGroup = $Machine.ResourceGroupName
    if ($Machine.OsType -eq "Windows") {
        $localUser = "Administrator"
    } else {
        $localUser = "jumpstart"
    }
    Write-Output "Creating session for $serverName with user $localUser"
    $configFile = "$env:TEMP\$serverName"

    Remove-Item $configFile -ErrorAction SilentlyContinue
    $null = Export-AzSshConfig -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser -ResourceType Microsoft.HybridCompute/machines -ConfigFilePath $configFile

    # Note: One option to avoid password prompt is to use the Run Command feature to populate the public key on the remote servers beforehand.

    # Use a regex pattern to find the ProxyCommand line and extract its value
    $proxyCommandPattern = 'ProxyCommand\s+"([^"]+)"\s+-r\s+"([^"]+)"'
    $match = Select-String -Path $configFile -Pattern $proxyCommandPattern

    $proxyCommandValue1 = [regex]::Match($match.Line, $proxyCommandPattern).Groups[1].Value
    $proxyCommandValue2 = [regex]::Match($match.Line, $proxyCommandPattern).Groups[2].Value
    $fullProxyCommandValue = "`"$proxyCommandValue1 -r $proxyCommandValue2`""

    $options = @{ ProxyCommand = $fullProxyCommandValue }

    $sessions += New-PSSession -HostName $serverName -UserName $localUser -Options $options -OutVariable session

}

$sessions

# One way to avoid password prompts is to use the Run Command feature to populate the public key on the remote servers beforehand.

# Enter an interactive session
Enter-PSSession -Session $sessions[0]

# Run a command
Invoke-Command -Session $sessions -ScriptBlock {Write-Host "Hello $(whoami) from PowerShell $($PSVersionTable.PSVersion.ToString()) $(hostname)" -ForegroundColor Green}

Invoke-Command -Session $sessions -FilePath C:\temp\script.ps1

# Clean-up
Get-PSSession | Remove-PSSession

# VS Code Remote - SSH
$serverName = "ArcBox-Win2K25"
$localUser = "Administrator"
$configFile = "~\.ssh\$serverName"

$SshConfig = Export-AzSshConfig -ResourceGroupName $resourceGroup -Name $serverName -LocalUser $localUser -ResourceType Microsoft.HybridCompute/machines -ConfigFilePath $configFile
$SshConfig.ConfigString

Set-Clipboard -Value $SshConfig.ConfigString

Add-Content -Path "~\.ssh\config" -Value $SshConfig.ConfigString

# Ensure to have the Remote - SSH extension installed in VS Code
# Next, open Remote Explorer in VS Code, right-click on the server and select "Connect in New Window"