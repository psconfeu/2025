function Invoke-LinuxCommand {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$false)]
        [switch]$Elevate,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Full','ResultsOnly','ReturnCodeOnly')]
        [string]$OutputFormat = 'Full',
        
        [Parameter(Mandatory=$false)]
        [switch]$ReturnErrors,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 2,
        
        [Parameter(Mandatory=$true, ParameterSetName='Remote')]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$false, ParameterSetName='Local')]
        [Parameter(Mandatory=$false, ParameterSetName='Remote')]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory=$false, ParameterSetName='Remote')]
        [int]$RemoteTimeout = 300
    )
    $result = [PSCustomObject]@{
        'ReturnCode' = $null
        'LinesReturned' = $null
        'LinesError' = @()
    }
    $errorFile = $null
    if ($ReturnErrors -and ($Command -notmatch '2\>(\&1|\/dev\/null)\s*$')) {
        $errorFile = ('/tmp/errstream.{0}' -f $PID)
        Write-Verbose ('Writing error stream to {0}' -f $errorFile)
    }
    if ((-not $PSBoundParameters.ContainsKey('ComputerName')) -or ([string]::IsNullOrWhiteSpace($ComputerName))) {
        # local execution
        if (-not $IsLinux) { 
            Write-Verbose 'This command is designed to be ran on Linux'
            return $null
        }
        if ($Elevate) {
            if ([System.Environment]::IsPrivilegedProcess) {
                Write-Verbose ('Running in privileged mode as {0}' -f [System.Environment]::UserName)
                if ($null -ne $errorFile) {
                    $runCmd = ('{0} 2>{1}' -f $Command, $errorFile)
                } else {
                    $runCmd = $Command
                }
                Write-Verbose ('Executing: {0}' -f $runCmd)
                $result.LinesReturned = Invoke-Expression -Command $runCmd
                $result.ReturnCode = $LASTEXITCODE
            } else {
                Write-Verbose ('Not running privileged, user = {0}' -f [System.Environment]::UserName)
                $tryPasswordless = $true
                if ($null -ne $Credential) {
                    if ($Credential.UserName -eq [System.Environment]::UserName) {
                        $tryPasswordless = $false
                    } else {
                        Write-Warning ('Credential supplied for {0}, session is running as {1}. Context switching for elevation is not implemented yet so we will try passwordless sudo.' -f $Credential.UserName, [System.Environment]::UserName)
                    }
                }
                if ($tryPasswordless) {
                    Write-Verbose ('Credential for {1} not supplied, trying passwordless sudo with {0} seconds timeout' -f $Timeout, [System.Environment]::UserName)
                    $runCmd = ('timeout -k {1} {1} sudo {0}' -f $Command, $Timeout)
                    if ($null -ne $errorFile) {
                        $runCmd = ('{0} 2>{1}' -f $runCmd, $errorFile)
                    }
                    Write-Verbose ('Executing: {0}' -f $runCmd)
                    $result.LinesReturned = Invoke-Expression -Command $runCmd
                    $result.ReturnCode = $LASTEXITCODE
                } else {
                    Write-Verbose ('Credential for [{0}] supplied' -f $Credential.UserName)
                    $plainTextPassword = $Credential.GetNetworkCredential().Password
                    $runCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, $plainTextPassword)
                    $logCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, ('*' * $plainTextPassword.Length))
                    if ($null -ne $errorFile) {
                        $runCmd = ('{0} 2>{1}' -f $runCmd, $errorFile)
                        $logCmd = ('{0} 2>{1}' -f $logCmd, $errorFile)
                    }
                    Write-Verbose ('Executing: {0}' -f $logCmd)
                    $result.LinesReturned = Invoke-Expression -Command $runCmd
                    $result.ReturnCode = $LASTEXITCODE
                    Remove-Variable 'plainTextPassword' -Force -EA SilentlyContinue
                    Remove-Variable 'runCmd' -Force -EA SilentlyContinue
                    [gc]::Collect()
                }
            }
        } else {
            if ($null -ne $errorFile) {
                $runCmd = ('{0} 2>{1}' -f $Command, $errorFile)
            } else {
                $runCmd = $Command
            }
            Write-Verbose ('Executing: {0}' -f $runCmd)
            $result.LinesReturned = Invoke-Expression -Command $runCmd
            $result.ReturnCode = $LASTEXITCODE
        }
        if ($null -ne $errorFile) {
            $result.LinesError = Get-Content -Path $errorFile -EA SilentlyContinue
            if (Test-Path -Path $errorFile) { Remove-Item -Path $errorFile -Force -EA SilentlyContinue }
        }
    } else {
        # remote execution
        if (Connect-LinuxComputer -ComputerName $ComputerName -Credential $Credential) {
            if ($Elevate) {
                $plainTextPassword = ($script:ConnectedComputers[$ComputerName]).Credential.GetNetworkCredential().Password
                $runCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, $plainTextPassword)
                $logCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, ('*' * $plainTextPassword.Length))
                if ($null -ne $errorFile) {
                    $runCmd = ('{0} 2>{1}' -f $runCmd, $errorFile)
                    $logCmd = ('{0} 2>{1}' -f $logCmd, $errorFile)
                }
                Write-Verbose ('Executing: {0} on {1}' -f $logCmd, $ComputerName)
            } else {
                if ($null -ne $errorFile) {
                    $runCmd = ('{0} 2>{1}' -f $Command, $errorFile)
                } else {
                    $runCmd = $Command
                }
                Write-Verbose ('Executing: {0} on {1}' -f $runCmd, $ComputerName)
            }
            try {
                $cmdResult = Invoke-SSHCommand -Command $runCmd -SSHSession ($script:ConnectedComputers[$ComputerName]).Session -TimeOut $RemoteTimeout -EA Stop
                if ($null -eq $cmdResult) {
                    Write-Warning 'SSH connection was established, but command could not be run. No exception was thrown.'
                    return $false
                } else {
                    $result.ReturnCode = $cmdResult.ExitStatus
                    $result.LinesReturned = $cmdResult.Output
                    if ($null -ne $errorFile) {
                        $errResult = Invoke-SSHCommand -Command ('cat {0}' -f $errorFile) -SSHSession ($script:ConnectedComputers[$ComputerName]).Session -TimeOut $RemoteTimeout -EA SilentlyContinue
                        $result.LinesError = $errResult.Output
                        $errResult = Invoke-SSHCommand -Command ('rm -f {0}' -f $errorFile) -SSHSession ($script:ConnectedComputers[$ComputerName]).Session -TimeOut $RemoteTimeout -EA SilentlyContinue
                    }
                }
            } catch {
                Write-Warning ('Error running remote command: {0}' -f $_.Exception.Message)
            }
            Remove-Variable 'plainTextPassword' -Force -EA SilentlyContinue
            Remove-Variable 'runCmd' -Force -EA SilentlyContinue
            [gc]::Collect()
        } else {
            Write-Warning ('Could not connect to computer {0}' -f $ComputerName)
            return $false
        }
    }
    switch ($OutputFormat) {
        'Full' { return $result }
        'ReturnCodeOnly' { return $result.ReturnCode }
        'ResultsOnly' { return $result.LinesReturned}
    }   
}