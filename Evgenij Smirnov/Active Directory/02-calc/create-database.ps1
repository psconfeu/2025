[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [string]$SQLServer = 'localhost',
    [Parameter(Mandatory=$false)]
    [string]$Database = 'PSCONF-AD',
    [Parameter(Mandatory=$false)]
    [string]$User = 'psconf',
    [Parameter(Mandatory=$false)]
    [string]$Password = '12345'
)
$dbconn = New-Object System.Data.SqlClient.SqlConnection
$dbconn.ConnectionString = ('Server={0};User Id={2};Password={3};' -f $SQLServer, $Database, $User, $Password)
$dbconn.Open()
$dbcmd = $dbconn.CreateCommand()
$dbcmd.CommandText = ("DROP DATABASE IF EXISTS [{0}]" -f $Database)
$dbcmd.ExecuteNonQuery()
$dbcmd.CommandText = ("CREATE DATABASE [{0}] ON PRIMARY ( NAME = N'{0}', FILENAME = N'S:\DATA\{0}.mdf' , SIZE = 5GB , MAXSIZE = UNLIMITED, FILEGROWTH = 1GB ) LOG ON ( NAME = N'{0}_log', FILENAME = N'S:\DATA\{0}_log.ldf' , SIZE = 1GB , MAXSIZE = 2048GB , FILEGROWTH = 256MB )" -f $Database)
$dbcmd.ExecuteNonQuery()
$dbcmd.CommandText = ("ALTER DATABASE [{0}] SET RECOVERY SIMPLE" -f $Database)
$dbcmd.ExecuteNonQuery()
$dbcmd.Dispose()
$dbconn.Close()

$dbconn.ConnectionString = ('Server={0};Database={1};User Id={2};Password={3};' -f $SQLServer, $Database, $User, $Password)
$dbconn.Open()
$dbSchema = @(
    'CREATE TABLE GroupMemberships (Parent VARCHAR(8000), Child VARCHAR(8000), Explicit TINYINT DEFAULT 0)'
    'CREATE INDEX IdxParent ON GroupMemberships(Parent, Explicit)'
    'CREATE INDEX IdxChild ON GroupMemberships(Child, Explicit)'
)
$dbcmd = $dbconn.CreateCommand()
foreach ($line in $dbSchema) {
    $dbcmd.CommandText = $line
    $dbcmd.ExecuteNonQuery()
}
$dbcmd.Dispose()
$dbconn.Close()