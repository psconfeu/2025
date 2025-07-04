param(
    [System.Diagnostics.ProcessStartInfo]$StartInfo
)

# Attempt to access a property
$fileName = $StartInfo.FileName
Write-Verbose -Verbose "Executable Path: $fileName"

# input: $processInfo = @{FileName='IExplore.exe'}
# run: .\demo.ps1 -StartInfo $processInfo