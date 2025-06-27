function Connect-LinuxComputer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
        [ValidateRange(2,86400)]
        [int]$Timeout = 20,
        [Parameter(Mandatory=$false)]
        [int]$RemoteTimeout = 300,
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )
    $cName = $ComputerName.Trim()
    if ($script:ConnectedComputers.ContainsKey($cName)) {
        # existing connection
        #2do check if connection still active and reconnect if it's not
        return $true
    } else {
        # new connection
        if ($PSBoundParameters.ContainsKey('Credential') -and ($null -ne $Credential)) {
            try {
                $session = New-SSHSession -ComputerName $cName -Credential $Credential -AcceptKey -EA Stop
                $connectionObject = [PSCustomObject]@{
                    'ComputerName' = $cName
                    'Session' = $session
                    'Credential' = $Credential
                    'UserName' = $Credential.UserName
                    'Established' = Get-Date
                    'OSDistro' = $null
                    'OSFamily' = $null
                    'OSVersion' = $null
                    'OSCaption' = $null
                }
                $osResult = Invoke-SSHCommand -Command 'cat /etc/os-release 2>/dev/null' -SSHSession $session -TimeOut $TimeOut -EA Stop
                if ($null -eq $osResult) {
                    Write-Warning 'SSH connection was established, but os-release could not be read'
                    return $false
                } elseif ($osResult.ExitStatus -ne 0) {
                    Write-Warning ('SSH connection was established, but os-release finished with status {0}' -f $osResult.ExitStatus)
                    return $false
                } else {
                    switch -Regex ($osResult.Output) {
                        '^\s*ID\=\"?(?<value>[^\"]+)\"?' {
                            $connectionObject.OSDistro = $Matches['value']
                        }
                        '^\s*ID_LIKE\=\"?(?<value>[^\"]+)\"?' {
                            $connectionObject.OSFamily = ($Matches['value']).Split(' ')
                        }
                        '^\s*VERSION_ID\=\"?(?<value>[^\"]+)\"?' {
                            $connectionObject.OSVersion = $Matches['value']
                        }
                        '^\s*PRETTY_NAME\=\"?(?<value>[^\"]+)\"?' {
                            $connectionObject.OSCaption = $Matches['value']
                        }
                    }
                }
                if ($null -eq $connectionObject.OSDistro) {
                    Write-Warning 'SSH connection was established, but os-release did not deliver a distro ID'
                    return $false
                }
                [void]$script:ConnectedComputers.Add($cName, $connectionObject)
                if ($PassThru) {
                    return $connectionObject
                } else {
                    return $true
                }
            } catch {
                Write-Warning ('Error establishing an SSH session: {0}' -f $_.Exception.Message)
                return $false
            }
        } else {
            # new connection but no credential supplied
            Write-Warning ('SSH connection to {0} was not previously established. Please supply a Credential to establish connection.' -f $cName)
            return $false
        }
    }
}