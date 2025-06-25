# Setting up in-depth
Get-PSFConfig -Module AutomatedLab | Format-Table Name, Value, Description

# Linux, non-root config
mkdir ~/automatedlab/Assets -p

# Once only, all hail Friedrich!
Set-PSFConfig -FullName AutomatedLab.LabAppDataRoot -Value $home/automatedlab -PassThru | Register-PSFConfig
Set-PSFConfig -FUllName AutomatedLab.ProductKeyFilePath -Value $home/automatedlab/Assets/ProductKeys.xml -PassThru | Register-PSFConfig
Set-PSFConfig -FUllName AutomatedLab.ProductKeyFilePathCustom -Value $home/automatedlab/Assets/ProductKeysCustom.xml -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.DiskDeploymentInProgressPath -Value $home/automatedlab/DiskDeploymentInProgress -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.SwitchDeploymentInProgressPath -Value $home/automatedlab/SwitchDeploymentInProgress -PassThru | Register-PSFConfig
Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value $home/labsources -PassThru | Register-PSFConfig

# Bootstrap lab sources content, switch content to preview
New-LabSourcesFolder
New-LabSourcesFolder -Force -Branch develop

# Headless/Non-interactive Environments: Disable all prompts
Set-PSFConfig -FullName AutomatedLab.DoNotPrompt -Value $true -PassThru | Register-PSFConfig

# Deploy a quick lab
New-LabDefinition -Name psconfjhpaz25 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName 'West Europe'

# We're on Linux - save time by using SSH, or lessen the pain of using WSMAN on Linux with PSWSMAN
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:SshPublicKeyPath'  = '~/.ssh/id_rsa.pub'
    'Add-LabMachineDefinition:SshPrivateKeyPath' = '~/.ssh/id_rsa'
    'Add-LabMachineDefinition:AzureRoleSize'     = 'Standard_D4s_v6'
    'Add-LabMachineDefinition:OperatingSystem'   = 'Windows Server 2022 Datacenter (Desktop Experience)'
}
Add-LabMachineDefinition -Name SRV001
Add-LabMachineDefinition -Name SRV002 -OperatingSystem 'Ubuntu Server 22.04 LTS "Jammy Jellyfish"'

# If not prompting, maybe sync the lab sources first
Sync-LabAzureLabSources

Install-Lab # Azure is s-l-o-o-o-w compared to a local Hyper-V, so I pre-ran it of course (took me ~10 minutes)

# How about the built-in roles?
# No function yet (hint hint: Good first issue)
[enum]::GetValues([AutomatedLab.Roles])
Get-LabMachineRoleDefinition -Syntax -Role RootDC
Get-LabMachineRoleDefinition -Syntax -Role RemoteDesktopSessionHost

# But what about custom roles?
Get-LabSnippet -Type CustomRole

# In case you didn't know about snippets: USE THEM ALREADY!
New-LabSnippet -Name MyCustomDomain -DependsOn LabDefinition -Description "Deploy Domain'n'Stuff" -Type Snippet -ScriptBlock {
    param ($DomainName)
    Add-LabDomainDefinition -Name $DomainName -Administrator 'Administrator' -AdministratorPassword 'P@ssw0rd'
}

New-LabSnippet -Name MyPki -DependsOn MyCustomDomain, LabDefinition -Type Snippet -ScriptBlock {
    'Doing more stuff'
}

Get-LabSnippet -Name LabDefinition, MyCustomDomain, MyPki | Invoke-LabSnippet -LabParameter @{Name = 'MyLab'; DomainName = 'mydomain.local' }

# Let's add a new role, and make it a custom one
# /home/jhp/repos/AutomatedLab/AutomatedLabCore/internal/templates/AutomatedLabCustomRole/PSMDInvoke.ps1
Invoke-PSMDTemplate -TemplateName AutomatedLabCustomRole -OutPath "$(Get-LabSourcesLocation -Local)/CustomRoles" -Name JustCustomThings

# Nice.
code "$(Get-LabSourcesLocation -Local)/CustomRoles/JustCustomThings/HostStart.ps1"

# Add some content
# HostStart, HostEnd run on the Host, while JustCustomThings.ps1 runs on the VMs
@'
'@ | Add-Content "$(Get-LabSourcesLocation -Local)/CustomRoles/JustCustomThings/HostStart.ps1"

# Add a VM with a custom role - be aware that these are Installation Activities
$role = Get-LabInstallationActivity -CustomRole JustCustomThings
Add-LabMachineDefinition -Name SRV003 -PostInstallationActivity $role

# But I think my role should be integrated!
# --> Update the Library, add new functionality to AutomatedLabCore, ideally include a validator
# Test locally, and then submit a PR ♥