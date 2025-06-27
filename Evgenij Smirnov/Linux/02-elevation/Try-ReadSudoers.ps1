[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(1,4)]
    [int]$Scenario
)
switch ($Scenario) {
    1 {
        $res = Invoke-Expression 'cat /etc/sudoers'
        $LASTEXITCODE
        if (0 -eq $LASTEXITCODE) { $res }
    }
    2 {
        $res = Invoke-Expression 'cat /etc/sudoers 2>/dev/null'
        $LASTEXITCODE
        if (0 -eq $LASTEXITCODE) { $res }
    }
    3 {
        $res = Invoke-Expression 'sudo -n cat /etc/sudoers 2>/dev/null'
        $LASTEXITCODE
        if (0 -eq $LASTEXITCODE) { $res }
    }
    4 {
        $secpw = Read-Host -Prompt ('PowerShell: Enter password for [{0}]' -f [Environment]::UserName) -AsSecureString
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($secpw)
        $pw = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        Write-Host ('echo ''{0}''|sudo -S cat /etc/sudoers 2>/dev/null' -f $pw)
        $res = Invoke-Expression ('echo ''{0}''|sudo -S cat /etc/sudoers 2>/dev/null' -f $pw)
        $LASTEXITCODE
        $res
        if (0 -eq $LASTEXITCODE) { $res }
    }
}