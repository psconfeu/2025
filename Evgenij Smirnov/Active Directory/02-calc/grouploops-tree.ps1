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

$masterList = New-Object System.Collections.Generic.HashSet[string]
$branches = New-Object System.Collections.Generic.List[System.Collections.Generic.List[string]]

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
#$sr.Filter = '(objectClass=group)'
$sr.Filter = '(&(objectClass=group)(member=*))'
[void]$sr.Controls.Add($prc)
[void]$sr.Attributes.Add('distinguishedName')
[void]$sr.Attributes.Add('memberOf')
$srInner = New-Object System.DirectoryServices.Protocols.SearchRequest
[void]$srInner.Attributes.Add('distinguishedName')
$srInner.Scope = [System.DirectoryServices.SearchScope]::Base
$curPage = 0
$oldTime = $dw.Elapsed.TotalSeconds
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    $curPage++
    Write-Host ('Page: {0} duration: {1:0.00} NumBranches: {2}' -f $curPage, ($dw.Elapsed.TotalSeconds - $oldTime), $branches.Count)
    $oldTime = $dw.Elapsed.TotalSeconds
    foreach ($item in $res.Entries) {
        $childDN = $item.Attributes['distinguishedName'][0]
        foreach ($parent in $item.Attributes['memberOf']) {
            $parentDN = [System.Text.Encoding]::UTF8.GetString($parent)
            $parentBranches = $branches.Where({$_[-1] -eq $parentDN})
            if ($parentBranches.Count -eq 0) {
                #Write-Host "New branch: $parentDN >> $childDN"
                $newBranch = New-Object System.Collections.Generic.List[string]
                $newBranch.Add($parentDN)
                $newBranch.Add($childDN)
                $branches.Add([System.Collections.Generic.List[string]]::new($newBranch))
            } else {
                foreach ($br in  $parentBranches) {
                    #Write-Host "Adding $childDN to $($br[0]) >> $parentDN"
                    $br.Add($childDN)
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