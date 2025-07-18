# Type conversion to a non-approved type is also not allowed, type conversion will call constructor of arbitrary type

$processInfo = @{fileName='IExplore.exe'}
$startInfo = [System.Diagnostics.ProcessStartInfo]$processInfo