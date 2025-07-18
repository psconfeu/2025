# Posture Control - PowerShell Experience on Windows Server 2025

# Install OSConfig module
Install-PSResource -Name Microsoft.OSConfig -Scope AllUsers -Repository PSGallery

# Verify OSConfig module installation
Find-PSResource -Name Microsoft.OSConfig

# Audit Scenario example
Get-OSConfigDesiredConfiguration -Scenario SSH
Get-OSConfigDesiredConfiguration -Scenario SSH | Format-Table Name, @{ Name = "Status"; Expression={$_.Compliance.Status} }, @{ Name = "Reason"; Expression={$_.Compliance.Reason} } -AutoSize -Wrap

# Configure Scenario example
$directiveName = "Ciphers"
$desiredValue = "aes128-ctr","aes192-ctr","aes256-ctr"
Set-OSConfigDesiredConfiguration -Scenario SSH -Name $directiveName -Value $desiredValue
