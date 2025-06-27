param(
    [switch]$All
)

# This script removes all Output*.csv files in the Output folder and temp files.
# If -All is specified, it also removes TestData*.csv files.

if ($All) {
    # Clean TestData*.csv from Input folder
    $TestDataPath = Join-Path -Path "Input" -ChildPath "TestData*.csv"
    Get-ChildItem -Path $TestDataPath | Remove-Item -Force -ErrorAction SilentlyContinue
} 

# Clean Output*.csv from Output folder
$OutputPath = Join-Path -Path "Output" -ChildPath "Output*.csv"
Get-ChildItem -Path $OutputPath | Remove-Item -Force -ErrorAction SilentlyContinue

# Always clean up temp files from Temp folder
$TempPath = Join-Path -Path "Temp" -ChildPath "*temp-groups*.csv"
Get-ChildItem -Path $TempPath | Remove-Item -Force -ErrorAction SilentlyContinue
