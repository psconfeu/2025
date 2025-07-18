[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$InputFolder = "Input",
    [Parameter(Mandatory = $false)][string]$OutputFile = (Join-Path -Path "Output" -ChildPath "Output-3.csv")
)

# Get all test CSV files and import data
$files = Get-ChildItem -Path $InputFolder -Filter "TestData*.csv"

# Initialize hash table and temp file
$hashTable = @{}
$tempFile = Join-Path -Path "Temp" -ChildPath "3-temp-groups.csv"

# Clean up any existing temp file
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

foreach ($file in $files) {
    Import-Csv -Path $file.FullName | ForEach-Object {
        # Create hash key from columns we want to group by
        $key = "$($_.ProductName)_$($_.ResourceId)"
        $hashKey = [int]$key.GetHashCode()
                
        # Check if hash key exists
        if ($hashTable.ContainsKey($hashKey)) {
            # Key exists - add sum to existing values
            $hashTable[$hashKey].Cost += [decimal]$_.Cost
            $hashTable[$hashKey].Quantity += [int]$_.Quantity  
        }
        else {
            # Create new entry in hash table
            $hashTable[$hashKey] = [PSCustomObject]@{
                                        Cost     = [decimal]$_.Cost
                                        Quantity = [int]$_.Quantity
                                    }
            
            # Write unique group to temp file
            [PSCustomObject]@{
                HashKey     = $hashKey
                ProductName = $_.ProductName
                ResourceId  = $_.ResourceId
            } | Export-Csv -Path $tempFile -NoTypeInformation -Append
        }
    }
}

# Combine temp file with hash table results
Import-Csv -Path $tempFile | ForEach-Object {
    [PSCustomObject]@{
        ProductName = $_.ProductName
        ResourceId  = $_.ResourceId
        Cost        = $hashTable[[int]$_.HashKey].Cost
        Quantity    = $hashTable[[int]$_.HashKey].Quantity
    }
} | Export-Csv -Path $OutputFile -NoTypeInformation 

# Show results
# Import-Csv -Path $OutputFile | Sort-Object ProductName, ResourceId
#  Import-Csv $tempFile
#  $hashTable


# Clean up temporary file
#Remove-Item -Path $tempFile -Force
