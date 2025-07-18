# Use of custom PowerShell classes is not allowed. They are just arbitrary C# type definitions

class Device {
    [string]$Brand
}

$dev = [Device]::new()
$dev.Brand = "Fabrikam, Inc."
$dev