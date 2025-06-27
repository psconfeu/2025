function Restart-LinuxComputer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Now
    )
    if (-not $IsLinux) { 
        Write-Verbose 'This command is designed to be ran on Linux'
        return $null
    }
    if ($Now) {
        $runCmd = 'shutdown -r --no-wall now'
    } else {
        $runCmd = 'shutdown -r --no-wall'
    }
    $cmdRes = Invoke-ElevatedCommand -Command $runCmd -ReturnErrors
    if ($cmdRes.returnCode -eq 0) {
        return $true
    } else {
        foreach ($line in $cmdRes.LinesError) {
            Write-Host $line -ForegroundColor Yellow
        }
        return $false
    }
}