[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 1000,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Root','Child')]
    [string]$Domain = 'Root',
    [Parameter(Mandatory=$false)]
    [string]$SQLServer = 'localhost',
    [Parameter(Mandatory=$false)]
    [string]$Database = 'PSCONF-AD',
    [Parameter(Mandatory=$false)]
    [string]$User = 'psconf',
    [Parameter(Mandatory=$false)]
    [string]$Password = '12345',
    [Parameter(Mandatory=$false)]
    [switch]$DoNotWriteToDB
)
if ($Domain -eq 'Root') {
    $path = 'OU=LAB,DC=mega,DC=korp'
    $server = 'MEGA-ROOT-DC01.mega.korp'
} else {
    $path = 'OU=LAB,DC=child,DC=mega,DC=korp'
    $server = 'MEGA-CHLD-DC01.child.mega.korp'
}
$dbconn = New-Object System.Data.SqlClient.SqlConnection
$dbconn.ConnectionString = ('Server={0};Database={1};User Id={2};Password={3};' -f $SQLServer, $Database, $User, $Password)
$dbconn.Open()
$dbcmd = $dbconn.CreateCommand()
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
[int64]$nRel = 0
$oldTime = $dw.Elapsed.TotalSeconds
while ($true) {
    $res = $co.SendRequest($sr)
    $prespC = $res.Controls[0]
    $curPage++
    Write-Host ('Page: {0} dur: {1:0.00} rels: {2}' -f $curPage, ($dw.Elapsed.TotalSeconds - $oldTime), $nRel)
    $oldTime = $dw.Elapsed.TotalSeconds
    foreach ($item in $res.Entries) {
        $childDN = $item.Attributes['distinguishedName'][0]  -replace "'","''"
        foreach ($mem in $item.Attributes['memberOf']) {
            $parentDN = [System.Text.Encoding]::UTF8.GetString($mem)
            $q = ("INSERT INTO GroupMemberships (Parent, Child, Explicit) VALUES ('{0}','{1}',1)" -f ($parentDN -replace "'","''"), $childDN)
            $dbcmd.CommandText = $q
            if (-not $DoNotWriteToDB) {
                [void]$dbcmd.ExecuteNonQuery()
            }
            $nRel++
        }
    }
    if ($prespC.Cookie.Length -eq 0) {
        break
    } else {
        $prc.Cookie = $prespC.Cookie 
    }
}


$dw.Stop()
$dbconn.Close()
Write-Host ('Took {0:0.000} seconds to record {1} relationships' -f $dw.Elapsed.TotalSeconds, $nRel)