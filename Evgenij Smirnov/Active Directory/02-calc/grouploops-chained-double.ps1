<#
  this one is different from grouploops-chained.ps1 in that the complete LDAP object stack for the inner loop
  is maintained separately from the outer loop.

  it did provide a measurable, albeit insignificant, acceleration, which surprised me a bit
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 1000,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Root','Child')]
    [string]$Domain = 'Root'
)
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
$coInner = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$coInner.SessionOptions.ProtocolVersion = 3
$coInner.Bind()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
$sr.Filter = '(&(objectCategory=group)(member=*))'
[void]$sr.Controls.Add($prc)
[void]$sr.Attributes.Add('distinguishedName')
$curPage = 0
$oldTime = $dw.Elapsed.TotalSeconds
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    $curPage++
    Write-Host ('Page: {0} duration: {1:0.00} Looped Groups: {2}' -f $curPage, ($dw.Elapsed.TotalSeconds - $oldTime), $loopedGroups.Count)
    if (($dw.Elapsed.TotalSeconds - $oldTime) -gt 5) {Start-Sleep -Seconds 1}
    $oldTime = $dw.Elapsed.TotalSeconds
    foreach ($item in $res.Entries) {
        $srInner = New-Object System.DirectoryServices.Protocols.SearchRequest
        [void]$srInner.Attributes.Add('distinguishedName')
        #[void]$srInner.Controls.Add($prc)
        $srInner.Scope = [System.DirectoryServices.SearchScope]::Base
        $srInner.DistinguishedName = $item.Attributes['distinguishedName'][0]
        # memberOf performance is double that of member
        $srInner.Filter = ('(&(objectCategory=group)(memberOf:1.2.840.113556.1.4.1941:={0}))' -f $item.Attributes['distinguishedName'][0])
        #$srInner.Filter = ('(&(objectCategory=group)(member={0}))' -f $item.Attributes['distinguishedName'][0])
        $resInner = $coInner.SendRequest($srInner)
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