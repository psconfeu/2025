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

function Compare-Array ($a1, $a2) {
    if ($a1.Count -ne $a2.Count) { return $false }
    $res = $true
    for ($i = 0; $i -lt $a1.Count; $i++) {
        if ($a1[$i] -ne $a2[$i]) {
            return $false
        }
    }
    return $true
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
[void]$sr.Attributes.Add('objectSid')
$srInner = New-Object System.DirectoryServices.Protocols.SearchRequest
[void]$srInner.Attributes.Add('distinguishedName')
[void]$srInner.Attributes.Add('tokenGroups')
$srInner.Scope = [System.DirectoryServices.SearchScope]::Base
$curPage = 0
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    $curPage++
    Write-Host ('Page: {0} time: {1:0.00}' -f $curPage, $dw.Elapsed.TotalSeconds)
    foreach ($item in $res.Entries) {
        
        $srInner.DistinguishedName = $item.Attributes['distinguishedName'][0]
        $srInner.Filter = ('(distinguishedName={0})' -f $item.Attributes['distinguishedName'][0])
        $resInner = $co.SendRequest($srInner)
        if ($resInner.Entries[0].Attributes['tokenGroups'].Count -gt 1) {
            foreach ($tokenSID in $resInner.Entries[0].Attributes['tokenGroups']) {
                if (Compare-Array -a1 $tokenSID -a2 $item.Attributes['objectSid'][0]) {
                    [void]$loopedGroups.Add($item.Attributes['distinguishedName'][0])
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