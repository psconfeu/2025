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
Add-Type -AssemblyName System.DirectoryServices.Protocols
$di = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier ($server, 389)
$co = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$co.SessionOptions.ProtocolVersion = 3
$co.Bind()

$dw = New-Object System.Diagnostics.Stopwatch

$timeClass = 0
$timeCategory = 0

for ($i=1; $i -le $Passes; $i++) {
    Write-Host "Pass $i of $Passes"
    #region objectClass
    $dw.Reset()
    $dw.Start()
    $sr = New-Object System.DirectoryServices.Protocols.SearchRequest
    $sr.DistinguishedName = $path
    $prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
    $sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
    $sr.Filter = '(objectClass=user)'
    [void]$sr.Controls.Add($prc)
    $null = $sr.Attributes.Add('distinguishedName')
    while ($true) {
        $res = $co.SendRequest($sr)
        $prespC = $res.Controls[0]
        foreach ($item in $res.Entries) {
            $tmpvar = $item.Attributes['distinguishedName'][0]
        }
        if ($prespC.Cookie.Length -eq 0) {
            break
        } else {
            $prc.Cookie = $prespC.Cookie 
        }
    }
    $dw.Stop()
    $timeClass += $dw.Elapsed.TotalSeconds
    
    #endregion
    #region objectCategory
    $dw.Reset()
    $dw.Start()
    $sr = New-Object System.DirectoryServices.Protocols.SearchRequest
    $sr.DistinguishedName = $path
    $prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
    $sr.Scope = [System.DirectoryServices.SearchScope]::Subtree
    $sr.Filter = '(objectCategory=person)'
    [void]$sr.Controls.Add($prc)
    $null = $sr.Attributes.Add('distinguishedName')
    while ($true) {
        $res = $co.SendRequest($sr)
        $prespC = $res.Controls[0]
        foreach ($item in $res.Entries) {
            $tmpvar = $item.Attributes['distinguishedName'][0]
        }
        if ($prespC.Cookie.Length -eq 0) {
            break
        } else {
            $prc.Cookie = $prespC.Cookie 
        }
    }
    $dw.Stop()
    $timeCategory += $dw.Elapsed.TotalSeconds
    #endregion
}
#region result
Write-Host ('CLASS:    {0:0.000} seconds' -f ($timeClass/$Passes))
Write-Host ('CATEGORY: {0:0.000} seconds' -f ($timeCategory/$Passes))
#endregion