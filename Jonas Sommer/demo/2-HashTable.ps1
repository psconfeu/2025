[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$InputFolder = "Input",
    [Parameter(Mandatory = $false)][string]$OutputFile = (Join-Path -Path "Output" -ChildPath "Output-2.csv")
)

# Get all test CSV files and import data
$files = Get-ChildItem -Path $InputFolder -Filter "TestData*.csv"

# Initialize hash table
$hashTable = @{}

foreach ($file in $files) {
    Import-Csv -Path $file.FullName | ForEach-Object {
        # Create key from Columns we want to group by
        $key = "$($_.ProductName)_$($_.ResourceId)"
        

        # Check if key exists
        if ($hashTable.ContainsKey($key)) {
            # Key exists - add sum to existing values
            $hashTable[$key].Cost += [decimal]$_.Cost
            $hashTable[$key].Quantity += [int]$_.Quantity
 
        }
        else {
           # Create new entry - only store cost and quantity
            $hashTable[$key] = [PSCustomObject]@{
                                    Cost     = [decimal]$_.Cost
                                    Quantity = [int]$_.Quantity
                                }
        }
    }
}

# Convert hash table to results and export
$hashTable.GetEnumerator() | ForEach-Object {
    $keyParts = $_.Key -split '_'
    [PSCustomObject]@{
        ProductName = $keyParts[0]
        ResourceId  = $keyParts[1]
        Cost        = $_.Value.Cost
        Quantity    = $_.Value.Quantity
    }
} | Export-Csv -Path $OutputFile -NoTypeInformation 

# Show results
# Import-Csv -Path $OutputFile | Sort-Object ProductName, ResourceId