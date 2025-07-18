param(
    [hashtable]$StartInfo
)

# TODO: do your own input validation before using param!
$fileNameInput = $StartInfo.FileName
$processInfoObj = [System.Diagnostics.ProcessStartInfo]$fileNameInput

# Attempt to access a property
$fileName = $processInfoObj.fileName
Write-Verbose -Verbose "Executable Path: $fileName"

# input: $processInfo = @{FileName='IExplore.exe'}
# run: .\demo.ps1 -StartInfo $processInfo