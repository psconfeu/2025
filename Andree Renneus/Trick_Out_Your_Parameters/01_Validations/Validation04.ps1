using namespace System.Management.Automation

class ValidateIsOnlineAttribute : ValidateArgumentsAttribute {
    [void] Validate(
        [object] $value,
        [EngineIntrinsics] $engineIntrinsics) {
        if (-not (Test-Connection $value -Quiet -Ping -Count 1 -TimeoutSeconds 1)) {
            throw [System.ArgumentException]::new(
                "$value is not reachable. Please check the server name or network connection."
            )
        }
    }
}

function Get-ServerInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateIsOnline()]
        [string] $ServerName
    )
    "Getting info for server: $ServerName"
}
#
Get-ServerInfo -ServerName 'localhost'
Get-ServerInfo -ServerName 'broken.localhost'
