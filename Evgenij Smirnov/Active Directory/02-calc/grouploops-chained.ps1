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
$loopedGroups = New-Object System.Collections.Generic.List[string]
$dw.Start()

Add-Type -AssemblyName System.DirectoryServices.Protocols
$di = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier ($server, 389)
$co = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$co.SessionOptions.ProtocolVersion = 3
$co.Bind()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
$sr.Filter = '(&(objectCategory=group)(member=*))'
[void]$sr.Controls.Add($prc)
[void]$sr.Attributes.Add('distinguishedName')
$srInner = New-Object System.DirectoryServices.Protocols.SearchRequest
[void]$srInner.Attributes.Add('distinguishedName')
$srInner.Scope = [System.DirectoryServices.SearchScope]::Base
$curPage = 0
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    $curPage++
    Write-Host ('Page: {0} time: {1:0.00}' -f $curPage, $dw.Elapsed.TotalSeconds)
    foreach ($item in $res.Entries) {
        $srInner.DistinguishedName = $item.Attributes['distinguishedName'][0]
        $srInner.Filter = ('(&(objectCategory=group)(memberOf:1.2.840.113556.1.4.1941:={0}))' -f $item.Attributes['distinguishedName'][0])
        $resInner = $co.SendRequest($srInner)
        if ($resInner.Entries.Count -gt 0) {
            [void]$loopedGroups.Add($item.Attributes['distinguishedName'][0])
        }
    }
    if ($prespC.Cookie.Length -eq 0) {
        break
    } else {
        $prc.Cookie = $prespC.Cookie 
    }
}

$dw.Stop()
Write-Host ('Took {0:0.000} seconds to find {1} looped groups' -f $dw.Elapsed.TotalSeconds, $loopedGroups.Count)