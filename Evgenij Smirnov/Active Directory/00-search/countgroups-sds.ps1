[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 1000,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Root','Child')]
    [string]$Domain = 'Root'
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
$allGroups = New-Object System.Collections.Generic.List[string]

$dw.Start()
$rootObj = [ADSI]('LDAP://{0}/{1}' -f $server, $path)
$ds = New-Object System.DirectoryServices.DirectorySearcher
$ds.SearchRoot = $rootObj
$ds.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
$ds.PageSize = $PageSize
$ds.Filter = '(objectClass=group)'
[void]$ds.PropertiesToLoad.Add('distinguishedName')
$res = $ds.FindAll()
foreach ($item in $res) { 
    [void]$allGroups.Add($item.Properties['distinguishedName'][0]) 
}
$dw.Stop()

Write-Host ('Took {0:0.000} seconds to enumerate {1} groups' -f $dw.Elapsed.TotalSeconds, $allGroups.Count)