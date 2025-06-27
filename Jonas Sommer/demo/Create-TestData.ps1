<#
.SYNOPSIS
    Creates test CSV files for Format-CorpBiExport demo
.DESCRIPTION
    Generates CSV files with sample data using emojis as identifiers
.PARAMETER NumberOfFiles
    The number of files to generate
.PARAMETER LinesPerFile
    The number of lines per file
.PARAMETER OutputDirectory
    The directory where the files will be created
.EXAMPLE
    New-TestDataFiles -NumberOfFiles 3 -LinesPerFile 5
#>



[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][int]$NumberOfFiles = 3,
    [Parameter(Mandatory = $false)][int]$LinesPerFile = 5,
    [Parameter(Mandatory = $false)][string]$OutputDirectory = (Join-Path -Path "." -ChildPath "input")
)
# Set culture to Danish to ensure decimal separator is comma (same as original script)
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')

# Create directory for test files if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Created directory: $OutputDirectory"
}

# Define emoji sets for product names and resource IDs
$productEmojis = "🍒", "🥝", "🍌", "🍊", "🍓" #, "🍇", "🍋", "Melon", "🍎", "🍍", "🍊"
$resourceEmojis = "💻", "📱", "📺"# "⌨️", "🖱️", "Kamera", "🖨️", "🖥️"

# Get the current month's dates
$currentMonth = Get-Date -Format "yyyy-MM"
$daysInMonth = [DateTime]::DaysInMonth((Get-Date).Year, (Get-Date).Month)

# Generate dates spread across the current month
$dates = 1..$daysInMonth | ForEach-Object {
    $dayString = "$_".PadLeft(2, '0')
    "$currentMonth-$dayString"
}

# Generate files
for ($fileNum = 1; $fileNum -le $NumberOfFiles; $fileNum++) {
    $filePath = Join-Path -Path $OutputDirectory -ChildPath "TestData$fileNum.csv"
    $fileData = @()

    # Generate data for this file
    for ($lineNum = 1; $lineNum -le $LinesPerFile; $lineNum++) {
        # Pick a date for this line - distribute dates across the month
        $dateIndex = [Math]::Floor(($lineNum / $LinesPerFile) * $dates.Count)
        $dateIndex = [Math]::Min([Math]::Max(0, $dateIndex), $dates.Count - 1)
        $date = $dates[$dateIndex]

        # Randomly select product and resource emojis
        # Ensure some overlap between files
        $productIndex = if ($lineNum % 3 -eq 0) {
            # Every 3rd line uses the same product based on file number for overlap
            $fileNum % $productEmojis.Count
        } else {
            Get-Random -Minimum 0 -Maximum $productEmojis.Count
        }

        $resourceIndex = if ($lineNum % 4 -eq 0) {
            # Every 4th line uses the same resource based on file number for overlap
            $fileNum % $resourceEmojis.Count
        } else {
            Get-Random -Minimum 0 -Maximum $resourceEmojis.Count
        }

        $product = $productEmojis[$productIndex]
        $resource = $resourceEmojis[$resourceIndex]

        # Generate random cost and quantity
        $cost = [Math]::Round((Get-Random -Minimum 5 -Maximum 50) + (Get-Random -Minimum 0 -Maximum 100) / 100, 2)
        $quantity = Get-Random -Minimum 1 -Maximum 10

        # Add data to the file
        $fileData += [PSCustomObject]@{
            ProductName = $product
            ResourceId  = $resource
            DateTime    = $date
            Cost        = $cost
            Quantity    = $quantity
        }
    }

    # Write the data to a CSV file
    $fileData | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 -Delimiter ","
}

Write-Host "Created $NumberOfFiles test files with $LinesPerFile lines each in $OutputDirectory"
