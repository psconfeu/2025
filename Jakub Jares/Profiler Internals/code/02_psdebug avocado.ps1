try {
    Set-PSDebug -Trace 1
    & "$PSScriptRoot/Write-Avocado.ps1" 
}
finally {
    Set-PSDebug -Off
}
