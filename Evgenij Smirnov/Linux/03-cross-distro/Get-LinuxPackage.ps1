<#
    .SYNOPSIS
    Retrieves information about installed packages.

    .DESCRIPTION
    Retrieves information about installed packages.

    .PARAMETER PackageName
    Optional. Specifies the name of the package.
    If omitted, all installed packages are returned.

    .INPUTS
    None. You can't pipe objects to Get-LinuxPackage.

    .OUTPUTS
    Array of objects representing packages.
    
    .EXAMPLE
    PS> Get-LinuxPackage -PackageName "cronie"
    #2do

#>
function Get-LinuxPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$PackageName
    )
    if (-not $IsLinux) { 
        Write-Verbose 'This command is designed to be ran on Linux'
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($script:osInfo.PackageManager)) {
        Write-Warning ('No package manager mapped to [{0}]' -f $script:osInfo.OSCaption)
        return $null
    }
    Write-Verbose ('Package enumeration for [{0}]' -f $script:osInfo.PackageManager)
    $result = @()
    switch ($script:osInfo.PackageManager) {
        'dpkg' {
            $pkgMgrMissing = ($null -eq (Invoke-Expression -Command 'which dpkg-query 2>/dev/null'))
            if ($pkgMgrMissing) {
                Write-Warning 'Missing package manager: dpkg'
                return $null
            }
            $pkgRaw = Invoke-Expression -Command 'dpkg-query -l'
            foreach ($line in $pkgRaw) {
                if ($line -match '^[\|\+]') { continue }
                if ($line -match '^[a-zA-Z]{2}\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<arch>\S+)\s+\S+') {
                    $result += [PSCustomObject]@{
                        'Name' = $Matches['name']
                        'Architecture' = $Matches['arch']
                        'Version' = $Matches['version']
                    }
                } else {
                    Write-Verbose ('Unmatched line: {0}' -f $line)
                }
            }
        }
        'dnf' {
            $pkgMgrMissing = ($null -eq (Invoke-Expression -Command 'which dnf 2>/dev/null'))
            if ($pkgMgrMissing) {
                Write-Warning 'Missing package manager: dnf'
                return $null
            }
            $pkgRaw = Invoke-Expression -Command 'dnf --installed --color never list'
            foreach ($line in $pkgRaw) {
                if ($line -match '(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+\@.+') {
                    $result += [PSCustomObject]@{
                        'Name' = $Matches['name']
                        'Architecture' = $Matches['arch']
                        'Version' = $Matches['version']
                    }
                } else {
                    Write-Verbose ('Unmatched line: {0}' -f $line)
                }
            }
        }
        'zypper' {
            $pkgMgrMissing = ($null -eq (Invoke-Expression -Command 'which zypper 2>/dev/null'))
            if ($pkgMgrMissing) {
                Write-Warning 'Missing package manager: zypper'
                return $null
            }
            $pkgRaw = Invoke-Expression -Command 'zypper search -is'
            foreach ($line in $pkgRaw) {
                if ($line -match '^i\+?\s+\|\s+(?<name>\S+)\s+\|\s+(\S+)\s+\|\s+(?<version>\S+)\s+\|\s+(?<arch>\S+)\s+\|\s+.*') {
                    $result += [PSCustomObject]@{
                        'Name' = $Matches['name']
                        'Architecture' = $Matches['arch']
                        'Version' = $Matches['version']
                    }
                } else {
                    Write-Verbose ('Unmatched line: {0}' -f $line)
                }
            }
        }
        default {
            Write-Warning ('No enumeration procedure defined for package manager "{0}"' -f $script:osInfo.PackageManager)
            return $null
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        $result = $result.Where({$_.Name -like $PackageName})
    }
    return $result
}