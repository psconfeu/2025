[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 1000,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Root','Child')]
    [string]$Domain = 'Root',
    [Parameter(Mandatory=$false)]
    [string]$UPN = 'joe.user@mega.korp',
    [Parameter(Mandatory=$false)]
    [switch]$DoNotEvaluate
)
if ($psISE) {
    ('& "{0}"' -f $MyInvocation.InvocationName) | Set-Clipboard
    exit
}
if ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Warning 'Does NOT run on Core!'
    exit
}
if ($Domain -eq 'Root') {
    $path = 'OU=LAB,DC=mega,DC=korp'
    $server = 'MEGA-ROOT-DC01.mega.korp'
} else {
    $path = 'OU=LAB,DC=child,DC=mega,DC=korp'
    $server = 'MEGA-CHLD-DC01.child.mega.korp'
}


function ConvertTo-SID {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $InputValue
    )
    if (24 -le $InputValue.Count) {
        $Val3 = $InputValue[15]
        $Val3 = $Val3 * 256 + $InputValue[14]
        $Val3 = $Val3 * 256 + $InputValue[13]
        $Val3 = $Val3 * 256 + $InputValue[12]
        $Val4 = $InputValue[19]
        $Val4 = $Val4 * 256 + $InputValue[18]
        $Val4 = $Val4 * 256 + $InputValue[17]
        $Val4 = $Val4 * 256 + $InputValue[16]
        $Val5 = $InputValue[23]
        $Val5 = $Val5 * 256 + $InputValue[22]
        $Val5 = $Val5 * 256 + $InputValue[21]
        $Val5 = $Val5 * 256 + $InputValue[20]
        if (26 -le $InputValue.Count) {
            $Val6 = $InputValue[25]
            $Val6 = $Val6 * 256 + $InputValue[24]
            $out = 'S-{0}-{1}-{2}-{3}-{4}-{5}-{6}' -f $InputValue[0], $InputValue[7], $InputValue[8], $Val3, $Val4, $Val5, $Val6
        } else {
            $out = 'S-{0}-{1}-{2}-{3}-{4}-{5}' -f $InputValue[0], $InputValue[7], $InputValue[8], $Val3, $Val4, $Val5
        }
    } elseif (16 -eq $InputValue.Count) {
        $Val3 = $InputValue[15]
        $Val3 = $Val3 * 256 + $InputValue[14]
        $Val3 = $Val3 * 256 + $InputValue[13]
        $Val3 = $Val3 * 256 + $InputValue[12]
        $out = 'S-{0}-{1}-{2}-{3}' -f $InputValue[0], $InputValue[7], $InputValue[8], $Val3
    } else {
        Write-Warning ('[ConvertTo-SID] Wrong byte count [{0}], should be 16, 24 or 26+' -f $InputValue.Count)
        $out = $null
    }
    return $out
}

Add-Type -AssemblyName System.DirectoryServices.Protocols
$di = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier ($server, 3268)
$co = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$co.SessionOptions.ProtocolVersion = 3
$co.Bind()
Write-Host 'Bound to GC'
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
$sr.Filter = ('(userPrincipalName={0})' -f $UPN)
[void]$sr.Attributes.Add('distinguishedName')
[void]$sr.Attributes.Add('objectSID')
Write-Host ('Sending request for [{0}]' -f $sr.Filter)
$res = $co.SendRequest($sr)
if ($res.Entries.Count -eq 0) {
    Write-Warning 'Principal not found in GC'
    exit
}
$sidBin = $res.Entries[0].Attributes['objectSID'][0]
$idrSID = ConvertTo-SID -InputValue $sidBin
Write-Host ('SID: {0}' -f $idrSID)
$co.Dispose()
$di = $null

if ([string]::IsNullOrWhiteSpace($idrSID)) { exit }

$dw = New-Object System.Diagnostics.Stopwatch
$allPerms = New-Object System.Collections.Generic.List[string]
$dw.Start()


$di = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier ($server, 389)
$co = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$co.SessionOptions.ProtocolVersion = 3
$co.Bind()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
$sr.Filter = '(objectClass=*)'
[void]$sr.Controls.Add($prc)
[void]$sr.Attributes.Add('distinguishedName')
[void]$sr.Attributes.Add('ntSecurityDescriptor')
$ads = New-Object System.DirectoryServices.ActiveDirectorySecurity
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    foreach ($item in $res.Entries) {
        $ads.SetSecurityDescriptorBinaryForm([byte[]]($item.Attributes['ntSecurityDescriptor'][0]))
        $tmpvar = $ads.Sddl
        if (-not $DoNotEvaluate) {
            if ($tmpvar -match $idrSID) {
                [void]$allPerms.Add($item.Attributes['distinguishedName'][0])
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
Write-Host ('Took {0:0.000} seconds to find {1} objects with permissions for {2}' -f $dw.Elapsed.TotalSeconds, $allPerms.Count, $UPN)