# Script blocks are allowed as long as they don't use reflection, type accelerators, or dynamic code execution
Get-Process | Where-Object { $_.CPU -gt 100 } | Select-Object -First 1