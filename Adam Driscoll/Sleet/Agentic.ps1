# PowerShell Universal Processes
# Retrieved on June 24, 2025

# Array of PowerShell Universal processes
$psuProcesses = @(
    [PSCustomObject]@{
        Name = "PowerShellUniversal.Host"
        Id = 23876
    },
    [PSCustomObject]@{
        Name = "Universal.Server"
        Id = 23920
    }
)

# Display the processes
Write-Host "PowerShell Universal Processes:"
$psuProcesses | Format-Table -AutoSize
