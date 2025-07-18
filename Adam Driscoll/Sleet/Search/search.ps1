$Source = 'https://psgalleryeu.blob.core.windows.net/gallery5/search/query'
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