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

[void]$srInner.Attributes.Add('msds-memberOfTransitive')

$srInner.Scope = [System.DirectoryServices.SearchScope]::Base
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    foreach ($item in $res.Entries) {
        $dn = $item.Attributes['distinguishedName'][0]
        $srInner.DistinguishedName = $dn

        $srInner.Filter = ('(distinguishedName={0})' -f $dn)

        $resInner = $co.SendRequest($srInner)
        if ($resInner.Entries[0].Attributes['msds-memberOfTransitive'].Count -gt 1) {
            foreach ($mot in $resInner.Entries[0].Attributes['msds-memberOfTransitive']) {
                if ([System.Text.Encoding]::UTF8.GetString($mot) -eq $dn) {
                    [void]$loopedGroups.Add($dn)
                    break
                }
            }
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