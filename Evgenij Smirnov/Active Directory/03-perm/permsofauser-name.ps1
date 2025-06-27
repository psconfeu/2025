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
if ($Domain -eq 'Root') {
    $path = 'OU=LAB,DC=mega,DC=korp'
    $server = 'MEGA-ROOT-DC01.mega.korp'
} else {
    $path = 'OU=LAB,DC=child,DC=mega,DC=korp'
    $server = 'MEGA-CHLD-DC01.child.mega.korp'
}
if ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Warning 'Does NOT run on Core!'
    exit
}
$idr = [System.Security.Principal.NTAccount]::new($UPN)
$idrName = [System.Security.Principal.WindowsIdentity]::new($UPN).Name

if ([string]::IsNullOrWhiteSpace($idrName)) { exit }
$idrName

$dw = New-Object System.Diagnostics.Stopwatch
$allPerms = New-Object System.Collections.Generic.List[string]
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
$sr.Filter = '(objectCategory=*)'
[void]$sr.Controls.Add($prc)
[void]$sr.Attributes.Add('distinguishedName')

[void]$sr.Attributes.Add('ntSecurityDescriptor')

$ads = New-Object System.DirectoryServices.ActiveDirectorySecurity
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    foreach ($item in $res.Entries) {

        $ads.SetSecurityDescriptorBinaryForm([byte[]]($item.Attributes['ntSecurityDescriptor'][0]))
        $tmpvar = $ads.Access
  
        if (-not $DoNotEvaluate) {
            if ($tmpvar.Where({$_.IdentityReference -eq $idrName}).Count -gt 0) {
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