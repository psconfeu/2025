function Invoke-ElevatedCommand {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Full','ResultsOnly','ReturnCodeOnly')]
        [string]$OutputFormat = 'Full',
        [Parameter(Mandatory=$false)]
        [switch]$ReturnErrors,
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 2
    )
    if (-not $IsLinux) { 
        Write-Verbose 'This command is designed to be executed on Linux'
        return $null
    }
    $errorFile = $null
    $result = [PSCustomObject]@{
        'ReturnCode' = $null
        'LinesReturned' = $null
        'LinesError' = @()
    }
    if ($ReturnErrors -and ($Command -notmatch '2\>(\&1|\/dev\/null)\s*$')) {
        $errorFile = ('/tmp/errstream.{0}' -f $PID)
        Write-Verbose ('Writing error stream to {0}' -f $errorFile)
    }
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
        if ($null -eq $script:SessionPassword) {
            Write-Verbose ('Session password not set, trying passwordless sudo with {0} seconds timeout' -f $Timeout)
            $runCmd = ('timeout -k {1} {1} sudo {0}' -f $Command, $Timeout)
            if ($null -ne $errorFile) {
                $runCmd = ('{0} 2>{1}' -f $runCmd, $errorFile)
            }
            Write-Verbose ('Executing: {0}' -f $runCmd)
            $result.LinesReturned = Invoke-Expression -Command $runCmd
            $result.ReturnCode = $LASTEXITCODE
        } else {
            Write-Verbose 'Session password set, trying sudo with password'
            $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($script:SessionPassword)
            $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
            $runCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, $plainTextPassword)
            $logCmd = ('echo ''{1}''|sudo -S {0}' -f $Command, ('*' * $plainTextPassword.Length))
            if ($null -ne $errorFile) {
                $runCmd = ('{0} 2>{1}' -f $runCmd, $errorFile)
                $logCmd = ('{0} 2>{1}' -f $logCmd, $errorFile)
            }
            Write-Verbose ('Executing: {0}' -f $logCmd)
            $result.LinesReturned = Invoke-Expression -Command $runCmd
            $result.ReturnCode = $LASTEXITCODE
        }
    }
    if ($null -ne $errorFile) {
        $result.LinesError = Get-Content -Path $errorFile -EA SilentlyContinue
        if (Test-Path -Path $errorFile) { Remove-Item -Path $errorFile -Force -EA SilentlyContinue }
    }
    switch ($OutputFormat) {
        'Full' { return $result }
        'ReturnCodeOnly' { return $result.ReturnCode }
        'ResultsOnly' { return $result.LinesReturned}
    }
}