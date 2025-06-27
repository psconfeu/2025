[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$InputFolder = "Input",
    [Parameter(Mandatory = $false)][string]$OutputFile = (Join-Path -Path "Output" -ChildPath "Output-4.csv"),
    [Parameter(Mandatory = $false)][int]$BufferSize = 3
)
# Get all test CSV files and import data
$files = Get-ChildItem -Path $InputFolder -Filter "TestData*.csv"

# Initialize hash table, temp file and buffer
$hashTable = @{}
$tempFile = Join-Path -Path "Temp" -ChildPath "4-temp-groups-buffered.csv"
$outputBuffer = [System.Collections.ArrayList]@()

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
            
            # Add unique group to buffer (ArrayList much more efficient than +=)
            [void]$outputBuffer.Add([PSCustomObject]@{
                                        HashKey     = $hashKey
                                        ProductName = $_.ProductName
                                        ResourceId  = $_.ResourceId
                                    })
            
            # Flush buffer when it reaches buffer size
            if ($outputBuffer.Count -ge $BufferSize) {
                $outputBuffer | Export-Csv -Path $tempFile -NoTypeInformation -Append
                $outputBuffer.Clear()
            }
        }
    }
}

# Flush remaining buffer
if ($outputBuffer.Count -gt 0) {
    $outputBuffer | Export-Csv -Path $tempFile -NoTypeInformation -Append
}

# Combine temp file with hash table results
Import-Csv -Path $tempFile | ForEach-Object {
    $hashKey = [int]$_.HashKey
    $aggregatedData = $hashTable[$hashKey]
    
    [PSCustomObject]@{
        ProductName = $_.ProductName
        ResourceId  = $_.ResourceId
        Cost        = $aggregatedData.Cost
        Quantity    = $aggregatedData.Quantity
    }
} | Export-Csv -Path $OutputFile -NoTypeInformation

# Show results
# Import-Csv -Path $OutputFile | Sort-Object ProductName, ResourceId

# clean up
# Remove-Item -Path $tempFile -Force
