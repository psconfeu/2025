New-PSUEndpoint -Url "/api/tester" -Method @('GET') -Endpoint {
    param(
        $Param1
    )

    @{
        Header     = $Headers["X-PSU"]
        Query      = $QueryItem
        ParamBlock = $Param1
    }
} 
New-PSUEndpoint -Url "/process" -Description "Gets a list of processes running on the PowerShell Universal server." -Method @('GET') -Endpoint {
    <#
.OUTPUTS
200:
  Description: An array of process information.
  Content:
      application/json: ProcessInfo[]

400:
  Description: Invalid input
#>
    param()

    Get-Process | Select-Object Name, Id
} -Documentation "Agent Docs" 
New-PSUEndpoint -Url "/process/:name" -Description "Starts a process on the PowerShell Universal server." -Endpoint {
    param(
        [Parameter(Mandatory, HelpMessage = "The file name of the process to start.")]
        $Name
    )

    Start-Process $Name -PassThru | Select-Object Name, Id
} -Documentation "Agent Docs" 
New-PSUEndpoint -Url "/psversiontable" -Method @('GET') -Endpoint {
    $PSVersionTable.PSVersion.ToString()
} -Environment "Windows PowerShell 5.1" 
New-PSUEndpoint -Url "/search/query" -Method @('GET') -Endpoint {
    $Source = 'https://psgalleryeu.blob.core.windows.net/gallery7/search/query'
    $skip = 0
    $take = 100

    $skipNum = -1

    if ([int]::TryParse($Skip, [ref] $skipNum) && $skipNum -gt -1) {
        $skip = $skipNum
    }

    $skipNum = -1

    if ([int]::TryParse($Take, [ref] $skipNum) && $skipNum -gt 0) {
        $take = $skipNum
    }

    $StaticResults = Invoke-RestMethod $Source

    if ($StaticResults -eq $null) {
        return @()
    }

    $Data = $StaticResults.Data

    $Data = $Data | Where-Object { $_.id -like "*$q*" -or $_.description -like "*$q*" }
    $Data = $Data | Sort-Object -Property id
    [array]$Data = $Data | Select-Object -Skip $skip -First $take

    @{
        index      = $StaticResults.index
        lastReopen = $StaticResults.lastReopen
        totalHits  = $Data.Count
        data       = $Data
        '@context' = $StaticResults.'@context'
    } | ConvertTo-Json
}