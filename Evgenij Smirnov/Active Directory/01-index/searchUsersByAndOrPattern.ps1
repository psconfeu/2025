[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 1000,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Root','Child')]
    [string]$Domain = 'Root',
    [Parameter(Mandatory=$false)]
    [int]$Passes = 10
)
if ($psISE) {
    ('& "{0}"' -f $MyInvocation.InvocationName) | Set-Clipboard
    exit
}
if ($Domain -eq 'Root') {
    $path = 'OU=LAB,DC=mega,DC=korp'
    $server = 'MEGA-ROOT-DC01.mega.korp'
} else {
    $path = 'OU=LAB,DC=child,DC=mega,DC=korp'
    $server = 'MEGA-CHLD-DC01.child.mega.korp'
}
$dw = New-Object System.Diagnostics.Stopwatch

$timeAnd = 0
$timeOr = 0

for ($i=1; $i -le $Passes; $i++) {
    Write-Host "Pass $i  of $Passes"
    #region inner AND
    $dw.Reset()
    $allUsers = New-Object System.Collections.Generic.List[string]
    $z = Get-Random -Maximum 100 -Minimum 1
    $dw.Start()
    $rootObj = [ADSI]('LDAP://{0}/{1}' -f $server, $path)
    $ds = New-Object System.DirectoryServices.DirectorySearcher
    $ds.SearchRoot = $rootObj
    $ds.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $ds.PageSize = $PageSize
    $ds.Filter = '(|(&(objectCategory=person)(adminDisplayName=a*))(&(objectCategory=person)(adminDisplayName=b*))(&(objectCategory=person)(adminDisplayName=c*)))'
    [void]$ds.PropertiesToLoad.Add('distinguishedName')
    $res = $ds.FindAll()
    foreach ($item in $res) { 
        [void]$allUsers.Add($item.Properties['distinguishedName'][0]) 
    }
    $dw.Stop()
    $timeAnd += $dw.Elapsed.TotalMilliSeconds
    $usrAnd = $allUsers.Count
    #endregion
    #region inner OR
    $dw.Reset()
    $allUsers = New-Object System.Collections.Generic.List[string]
    $z = Get-Random -Maximum 100 -Minimum 1
    $dw.Start()
    $rootObj = [ADSI]('LDAP://{0}/{1}' -f $server, $path)
    $ds = New-Object System.DirectoryServices.DirectorySearcher
    $ds.SearchRoot = $rootObj
    $ds.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $ds.PageSize = $PageSize
    $ds.Filter = '(&(objectCategory=person)(|(adminDisplayName=a*)(adminDisplayName=b*)(adminDisplayName=c*)))'
    [void]$ds.PropertiesToLoad.Add('distinguishedName')
    $res = $ds.FindAll()
    foreach ($item in $res) { 
        [void]$allUsers.Add($item.Properties['distinguishedName'][0]) 
    }
    $dw.Stop()
    $timeOr += $dw.Elapsed.TotalMilliSeconds
    $usrOr = $allUsers.Count
    #endregion
}
#region result
Write-Host ('inner AND: {0:0.000} milliseconds {1} users' -f ($timeAnd/$Passes), $usrAnd)
Write-Host ('inner OR : {0:0.000} milliseconds {1} users' -f ($timeOr/$Passes), $usrOr)
#endregion