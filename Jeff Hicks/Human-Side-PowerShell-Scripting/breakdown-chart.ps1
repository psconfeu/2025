#requires -version 7.5

Param($Path = ".")
#sample using the pwshSpectreConsole Module
. $PSScriptRoot\Get-FileExtensionInfo.ps1
$r = Get-FileExtensionInfo $Path -recurse

$colors = @(
    "green",
    "gold1",
    "slateblue1",
    "lime",
    "aqua",
    "yellow",
    "orchid",
    "salmon1",
    "tan",
    "orange1"
)

$TotalFiles = ($r | Measure-Object count -sum).sum
$data = @()
#filter out files with no extensions
$info = $r | Where-Object Extension | Sort-Object count -Descending | Select-Object -first 10

for ($i = 0; $i -lt $info.count; $i++) {
    $v = $info[$i].count / $TotalFiles * 100
    $data += New-SpectreChartItem -Label $info[$i].extension -Value ([math]::Round($v,2)) -Color $colors[$i]

}

$Title =  "$($r[0].Path) - Top 10 File Extensions"
Format-SpectreBreakdownChart -Data $data -Width 100 -ShowPercentage |
Format-SpectrePanel -Title $title -Color HotPink -Border none
Write-SpectreHost "`n[italic]Total Files Analyzed[/]: [HotPink]$TotalFiles[/]"
