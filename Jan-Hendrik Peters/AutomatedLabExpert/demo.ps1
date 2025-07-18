#region Setup and Config

# Setting up in-depth
Import-Module AutomatedLabCore
Get-PSFConfig -Module AutomatedLab | Format-Table Name, Value, Description

# Linux, non-root config
mkdir ~/automatedlab/Assets -p

# Once only, all hail Friedrich!
Set-PSFConfig -FullName AutomatedLab.LabAppDataRoot -Value $home/.automatedlab -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.ProductKeyFilePath -Value $home/.automatedlab/Assets/ProductKeys.xml -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.ProductKeyFilePathCustom -Value $home/.automatedlab/Assets/ProductKeysCustom.xml -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.DiskDeploymentInProgressPath -Value $home/.automatedlab/DiskDeploymentInProgress -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.SwitchDeploymentInProgressPath -Value $home/.automatedlab/SwitchDeploymentInProgress -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value $home/automatedlabsources -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.Recipe.SnippetStore -Value $home/.automatedlab/snippets -PassThru | Register-PSFConfig

# Headless/Non-interactive Environments: Disable all prompts
# Turn off telemetry, do not sync lab sources content
Set-PSFConfig -FullName AutomatedLab.DoNotPrompt -Value $true -PassThru | Register-PSFConfig

# Bootstrap lab sources content, switch content to preview
# Unconfigured, it would on Windows be C:\LabSources and on Linux $home/automatedlabsources
# Unless you used the msi :)
New-LabSourcesFolder
New-LabSourcesFolder -Force -Branch develop

#endregion

#region Deploy a quick lab
New-LabDefinition -Name psconfjhpaz25 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName 'West Europe' -Subscription 'does not exist'

# We're on Linux - save time by using SSH, or lessen the pain of using WSMAN on Linux with PSWSMAN
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:SshPublicKeyPath'  = '~/.ssh/AzurePubKey.pub'
    'Add-LabMachineDefinition:SshPrivateKeyPath' = '~/.ssh/AzurePubKey'
    'Add-LabMachineDefinition:AzureRoleSize'     = 'Standard_D4s_v6'
    'Add-LabMachineDefinition:OperatingSystem'   = 'Windows Server 2022 Datacenter (Desktop Experience)'
}

# How did you know which size to use?
(Get-Command -MOdule *AutomatedLab*).Count
Get-Command -Module AutomatedLab.Common # -> Common helper module, very useful outside of AutomatedLab

Get-LabAzureAvailableRoleSize -LocationName westeurope |
Where NumberOfCores -eq 4 | 
Format-Table Name, NumberOfCores, MemoryInMB

Add-LabMachineDefinition -Name SRV001
Add-LabMachineDefinition -Name SRV002 -OperatingSystem 'Ubuntu Server 22.04 LTS "Jammy Jellyfish"'

# If not prompting, maybe sync the lab sources first
Sync-LabAzureLabSources

Install-Lab # Azure is s-l-o-o-o-w compared to a local Hyper-V, so I pre-ran it of course (took me ~10 minutes)

Import-Lab -Name psconfjhpaz25 -NoValidation
Get-LabVM
Start-LabVm -All

#endregion

#region Interaction options, lab extensions
(Get-Command -Module AutomatedLab*).Count

# DO NOT DO
New-PSSession -ComputerName ??? # What would it even be? It's on Azure...
(Get-LabVm -ComputerName SRV001).AzureConnectionInfo # Theoretically, you could grab the DNS name and port, but why would you?

# Do instead
# AutomatedLab manages sessions for you, and only creates new ones when needed
$session = New-LabPSSession -ComputerName SRV001 -Verbose

# DO NOT DO
Invoke-Command -Session $session -ScriptBlock { 'Some important task' }

# Do instead
Invoke-LabCommand -ComputerName SRV001 -ScriptBlock { 'Some important task' } -PassThru

(Get-LabVM -ComputerName SRV001).GetCredential((Get-Lab)).GetNetworkCredential().Password
(Get-LabVM -ComputerName SRV001).GetLocalCredential()

# DO NOT DO
$uri = 'https://github.com/AutomatedLab/AutomatedLab/blob/develop/Assets/Automated-Lab_icon128.png?raw=true'
Invoke-RestMethod -Uri $uri -OutFile ~/automatedlabsources/SoftwarePackages/thelogo.png
Copy-Item -ToSession $session  ~/automatedlabsources/SoftwarePackages/thelogo.png -Destination C:\

# Do instead
$labSources # Automatic global variable which always points to the lab sources for your currently selected hypervisor
code /home/jhp/source/repos/AutomatedLab/AutomatedLabCore/internal/scripts/Initialization.ps1

# GLIF automatically stores this in your upstream storage account on Azure, but you could also download locally and sync
Get-LabInternetFile -Uri $uri -Path "$labsources/SoftwarePackages" -FileName 'thelogo.png'

# How can we update our lab?
# Either:
Import-LabDefinition -Name psconfjhpaz25
Remove-LabMachineDefinition -Name SRV001
Add-LabMachineDefinition -Name SRV001 -Roles RootDC -DomainName contoso.local
Install-Lab

# Or update the original lab script
New-LabDefinition -Name psconfjhpaz25 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName 'West Europe'

# We're on Linux - save time by using SSH, or lessen the pain of using WSMAN on Linux with PSWSMAN
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:SshPublicKeyPath'  = '~/.ssh/AzurePubKey.pub'
    'Add-LabMachineDefinition:SshPrivateKeyPath' = '~/.ssh/AzurePubKey'
    'Add-LabMachineDefinition:AzureRoleSize'     = 'Standard_D4s_v6'
    'Add-LabMachineDefinition:OperatingSystem'   = 'Windows Server 2022 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name SRV001 -Roles RootDC, CARoot -DomainName contoso.local
Add-LabMachineDefinition -Name SRV002 -DomainName contoso.local -Roles WindowsAdminCenter, AzDevOps -OperatingSystem 'Ubuntu Server 22.04 LTS "Jammy Jellyfish"'

Install-Lab
#endregion

#region Roles
# How about the built-in roles?
# No function yet (hint hint: Good first issue)
[enum]::GetValues([AutomatedLab.Roles])

# Roles have syntax, and (online) help at automatedlab.org
Get-LabMachineRoleDefinition -Syntax -Role RootDC
Get-LabMachineRoleDefinition -Syntax -Role AzDevOps

# Machines can be references
$role = Get-LabMachineRoleDefinition -Role AzDevOps -Parameters @{
    PAT = 'abc'
    Organisation = 'https://dev.azure.com/JHP'
}
Add-LabMachineDefinition -Name SRV003 -Roles AzDevOps -SkipDeploment

# But what about custom roles?
Get-LabSnippet -Type CustomRole
Get-LabSnippet -Type SampleScript

# In case you didn't know about snippets: USE THEM ALREADY!
New-LabSnippet -Name MyCustomDomain -DependsOn LabDefinition -Description "Deploy Domain'n'Stuff" -Type Snippet -ScriptBlock {
    param ($DomainName)
    Add-LabDomainDefinition -Name $DomainName -Administrator 'Administrator' -AdministratorPassword 'P@ssw0rd'
}

New-LabSnippet -Name MyPki -DependsOn MyCustomDomain, LabDefinition -Type Snippet -ScriptBlock {
    'Doing more stuff'
}

Get-LabSnippet -Name MyCustomDomain, MyPki | Invoke-LabSnippet -LabParameter @{Name = 'MyLab'; DomainName = 'mydomain.local' }

# Let's add a new role, and make it a custom one
# Simple:
New-LabSnippet -Type CustomRole -Name AutomatedLabCustomRoleSimple -ScriptBlock {
    # This is the equivalent to <RoleName>.ps1 and will be executed on the VM
}

# Or more flexible with Fred's excellent templating module (Requires PSModuleDevelopment)
# Until I add this to AutomatedLab... -> /home/jhp/source/repos/AutomatedLab/AutomatedLabCore/internal/templates/AutomatedLabCustomRole/PSMDInvoke.ps1
Invoke-PSMDTemplate -TemplateName AutomatedLabCustomRole -OutPath "$(Get-LabSourcesLocation -Local)/CustomRoles" -Name JustCustomThings

# Nice.
code "$(Get-LabSourcesLocation -Local)/CustomRoles/JustCustomThings/HostStart.ps1"

# Add some content
# HostStart, HostEnd run on the Host, while JustCustomThings.ps1 runs on the VMs
@'
'@ | Add-Content "$(Get-LabSourcesLocation -Local)/CustomRoles/JustCustomThings/HostStart.ps1"

# Add a VM with a custom role - be aware that these are Installation Activities
$role = Get-LabInstallationActivity -CustomRole JustCustomThings
Add-LabMachineDefinition -Name SRV003 -PostInstallationActivity $role -PreInstallationActivity $role

# But I think my role should be integrated!
# --> Update the Library, add new functionality to AutomatedLabCore, ideally include a validator
# Test locally, and then submit a PR ♥
#endregion
