function Get-LinuxOS {
    [CmdletBinding()]
    Param()
    if (-not $IsLinux) { 
        Write-Verbose 'This command is designed to be ran on Linux'
        return $null
    }
    try {
        $osRelease = Invoke-Expression 'cat /etc/os-release' -EA Stop
    } catch {
        Write-Warning $_.Exception.Message
        return
    }
    $result = [PSCustomObject]@{
        'OSFamily' = $null
        'OSDistro' = $null
        'OSVersion' = $null
        'OSCaption' = $null
        'PkgMgrDistroId' = $null
        'PackageManager' = $null
    }
    switch -Regex ($osRelease) {
        '^\s*ID\=\"?(?<value>[^\"]+)\"?' {
            $result.OSDistro = $Matches['value']
        }
        '^\s*ID_LIKE\=\"?(?<value>[^\"]+)\"?' {
            $result.OSFamily = ($Matches['value']).Split(' ')
        }
        '^\s*VERSION_ID\=\"?(?<value>[^\"]+)\"?' {
            $result.OSVersion = $Matches['value']
        }
        '^\s*PRETTY_NAME\=\"?(?<value>[^\"]+)\"?' {
            $result.OSCaption = $Matches['value']
        }
    }
    $knownDistros = @('ubuntu','debian','rhel','fedora','suse')
    if ($result.OSDistro -in $knownDistros) {
        $result.PkgMgrDistroId = $result.OSDistro
    } else {
        foreach ($distLike in $result.OSFamily) {
            if ($distLike -in $knownDistros) {
                $result.PkgMgrDistroId = $distLike
                break
            }
        }
    }
    switch ($result.PkgMgrDistroId) {
        'ubuntu' { $result.PackageManager = 'dpkg' }
        'debian' { $result.PackageManager = 'dpkg' }
        'rhel' { $result.PackageManager = 'dnf' }
        'fedora' { $result.PackageManager = 'dnf' }
        'suse' { $result.PackageManager = 'zypper' }
    }
    return $result
}