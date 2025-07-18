[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$InputFolder = "Input",
    [Parameter(Mandatory = $false)][string]$OutputFile = (Join-Path -Path "Output" -ChildPath "Output-1.csv")
)

# Get all test CSV files and import data
$files = Get-ChildItem -Path $InputFolder -Filter "TestData*.csv"
$allData = $files | ForEach-Object { Import-Csv -Path $_.FullName }

# Group by ProductName and ResourceId
$groupedData = $allData | Group-Object -Property ProductName, ResourceId

# Sum up Cost and Quantity for each group
$groupedData | ForEach-Object {
    $totalCost = ($_.Group | Measure-Object -Property Cost -Sum).Sum
    $totalQuantity = ($_.Group | Measure-Object -Property Quantity -Sum).Sum
    $firstItem = $_.Group[0]
    
    [PSCustomObject]@{
        ProductName = $firstItem.ProductName
        ResourceId  = $firstItem.ResourceId
        Cost        = [decimal]$totalCost
        Quantity    = [int]$totalQuantity
    }
} | Export-Csv -Path $OutputFile -NoTypeInformation 

# Show results
# Import-Csv -Path $OutputFile | Sort-Object ProductName, ResourceId