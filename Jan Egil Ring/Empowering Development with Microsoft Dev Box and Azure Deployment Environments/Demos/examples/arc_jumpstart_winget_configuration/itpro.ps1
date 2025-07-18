# PowerShell DSC Configuration - IT Pro Setup
# Equivalent to itpro.dsc.yml for WinGet Configuration

Configuration ITPro_Setup
{
    param()

    # Import required DSC resource modules
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'HyperVDsc'
    Import-DscResource -ModuleName 'NetworkingDsc'

    Node localhost
    {
        # Install 7zip using Package resource (equivalent to WinGetPackage)
        Package Install7Zip
        {
            Name = '7-Zip'
            Path = 'winget'
            ProductId = '7zip.7zip'
            Arguments = '--source winget --silent'
            Ensure = 'Present'
        }

        # Install Hyper-V Windows Feature
        WindowsFeature HyperV
        {
            Name = 'Hyper-V'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }

        # Configure VM Host settings
        VMHost VMHostSettings
        {
            IsSingleInstance = 'Yes'
            EnableEnhancedSessionMode = $true
            DependsOn = '[WindowsFeature]HyperV'
        }

        # Configure VM Switch
        VMSwitch InternalNATSwitch
        {
            Name = 'InternalNATSwitch'
            Ensure = 'Present'
            Type = 'Internal'
            DependsOn = '[VMHost]VMHostSettings'
        }

        # Configure VM Switch vNIC IP Address
        IPAddress VMSwitchIPAddress
        {
            InterfaceAlias = 'vEthernet (InternalNATSwitch)'
            IPAddress = '10.10.1.1/24'
            AddressFamily = 'IPv4'
            KeepExistingAddress = $false
            DependsOn = '[VMSwitch]InternalNATSwitch'
        }
    }
}

# Generate the MOF file
Write-Host "Generating DSC Configuration MOF file..." -ForegroundColor Green
ITPro_Setup -OutputPath "./ITPro_Setup"

Write-Host @"

DSC Configuration generated successfully!

To apply this configuration:
1. Ensure you have the required DSC resource modules installed:
   - Install-Module PSDscResources -Force
   - Install-Module HyperVDsc -Force
   - Install-Module NetworkingDsc -Force

2. Enable WinRM for DSC (run as Administrator):
   Set-WSManQuickConfig -Force

3. Apply the configuration:
   Start-DscConfiguration -Path './ITPro_Setup' -Wait -Verbose

4. Check configuration status:
   Get-DscConfiguration
   Test-DscConfiguration -Path './ITPro_Setup'

Note: This configuration requires administrative privileges and will:
- Install 7-Zip
- Enable Hyper-V feature
- Configure Hyper-V host settings
- Create an internal VM switch
- Configure network settings for the VM switch

"@ -ForegroundColor Cyan
