[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('MEGA-ROOT-DC01.mega.korp','MEGA-CHLD-DC01.child.mega.korp')]
    [string]$Server = 'MEGA-ROOT-DC01.mega.korp'
)
$rootDSE = [ADSI]('LDAP://{0}/RootDSE' -f $Server)
$ntdsaObject = $rootDSE.dsServiceName[0]
$rootObj = [ADSI]('LDAP://{0}/{1}' -f $Server, $rootDSE.configurationNamingContext[0])
$ds = New-Object System.DirectoryServices.DirectorySearcher
$ds.SearchRoot = $rootObj
$ds.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
$ds.PageSize = 1000
$ds.Filter = ('(&(objectClass=nTDSDSA)(distinguishedName={0}))' -f $ntdsaObject)
[void]$ds.PropertiesToLoad.Add('queryPolicyObject')
$res = $ds.FindOne()
if ($res[0].Properties['queryPolicyObject'].Count -gt 0) {
    $filter = ('(distinguishedName={0})' -f $res[0].Properties['queryPolicyObject'][0])
} else {
    $filter = '(&(objectClass=queryPolicy)(cn=Default Query Policy))'
}
$ds.Filter = $filter
$ds.PropertiesToLoad.Clear()
[void]$ds.PropertiesToLoad.Add('lDAPAdminLimits')
$res = $ds.FindOne()
if (($res[0].Properties['lDAPAdminLimits']).Where({$_ -match 'MaxPageSize=(?<pagesize>\d+)'})) {
    $Matches['pagesize']
}