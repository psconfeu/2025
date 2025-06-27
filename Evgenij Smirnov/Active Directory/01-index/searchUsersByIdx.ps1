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
Add-Type -AssemblyName System.DirectoryServices.Protocols
$di = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier ($server, 389)
$co = New-Object System.DirectoryServices.Protocols.LdapConnection ($di,$null,[System.DirectoryServices.Protocols.AuthType]::Negotiate)
$co.SessionOptions.ProtocolVersion = 3
$co.Bind()



$dw = New-Object System.Diagnostics.Stopwatch
#region unindexed integer
#('(&(objectCategory=user)(psConfIntUni={0}))' -f $z)
$allUsers = New-Object System.Collections.Generic.List[string]
$z = Get-Random -Maximum 100 -Minimum 1
$dw.Start()

$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree

$sr.Filter = ('(&(objectCategory=user)(psConfIntUni={0}))' -f $z)

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
$timeIntUni = $dw.Elapsed.TotalSeconds
Remove-Variable 'allUsers'
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
#endregion
#region unindexed string
$dw.Reset()
$allUsers = New-Object System.Collections.Generic.List[string]
$z = Get-Random -Maximum 100 -Minimum 1
$dw.Start()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree

$sr.Filter = ('(&(objectCategory=user)(psConfStrUni={0}))' -f $z)

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
$timeStrUni = $dw.Elapsed.TotalSeconds
Remove-Variable 'allUsers'
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
#endregion
#region indexed integer
$dw.Reset()
$allUsers = New-Object System.Collections.Generic.List[string]
$z = Get-Random -Maximum 100 -Minimum 1
$dw.Start()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree

$sr.Filter = ('(&(objectCategory=user)(psConfIntIdx={0}))' -f $z)

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
$timeIntIdx = $dw.Elapsed.TotalSeconds
Remove-Variable 'allUsers'
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
#endregion
#region indexed string
$dw.Reset()
$allUsers = New-Object System.Collections.Generic.List[string]
$z = Get-Random -Maximum 100 -Minimum 1
$dw.Start()
$sr = New-Object System.DirectoryServices.Protocols.SearchRequest
$sr.DistinguishedName = $path
$prc = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize)
$sr.Scope = [System.DirectoryServices.SearchScope]::Subtree

$sr.Filter = ('(&(objectCategory=user)(psConfStrIdx={0}))' -f $z)

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
$timeStrIdx = $dw.Elapsed.TotalSeconds
Remove-Variable 'allUsers'
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
#endregion
#region output
@(
    [PSCustomObject][ordered]@{
        'Field' = 'String'
        'Indexed' = ('{0:0.000}' -f $timeStrIdx)
        'Unindexed' = ('{0:0.000}' -f $timeStrUni)
        'Ratio' = ('{0:0.00}' -f ($timeStrUni/$timeStrIdx))
    }
    [PSCustomObject][ordered]@{
        'Field' = 'Integer'
        'Indexed' = ('{0:0.000}' -f $timeIntIdx)
        'Unindexed' = ('{0:0.000}' -f $timeIntUni)
        'Ratio' = ('{0:0.00}' -f ($timeIntUni/$timeIntIdx))
    }
) | ft
#endregion