function Stop-LinuxComputer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Now,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory=$false)]
        [int]$RemoteTimeout = 300
    )
    $commonParms = @{}
    $cName = $null
    if ($PSBoundParameters.ContainsKey('ComputerName')) {
        $cName = $ComputerName.Trim()
        $commonParms.Add('ComputerName', $cName)
        if ($PSBoundParameters.ContainsKey('RemoteTimeout')) {
            $commonParms.Add('RemoteTimeout', $RemoteTimeout)
        }
    } elseif (-not $IsLinux) {
        Write-Verbose 'This command is designed to be ran on Linux'
        return $null
    }
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $commonParms.Add('Credential', $Credential)
    }
    if ($null -ne $cName) {
        if (-not (Connect-LinuxComputer @commonParms)) {
            Write-Warning ('Could not connect to {0}' -f $cName)
            return $null
        }
    }
    if ($Now) {
        $runCmd = 'shutdown -P --no-wall now'
    } else {
        $runCmd = 'shutdown -P --no-wall'
    }
    $cmdRes = Invoke-LinuxCommand @commonParms -Command $runCmd -ReturnErrors -Elevate
    if ($cmdRes.ReturnCode -eq 0) {
        return $true
    } else {
        foreach ($line in $cmdRes.LinesError) {
            Write-Host $line -ForegroundColor Yellow
        }
        return $false
    }
}