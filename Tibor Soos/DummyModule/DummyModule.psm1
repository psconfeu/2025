param(
    $LogName
)

function Get-DMInfo {
    New-LogEntry "Log entry from DummyModule, value of `$a : $a" -type Warning

    $cs = Get-PSCallStack

    New-LogEntry "Value of `$a via `$psboundparameters : $($cs[1].InvocationInfo.BoundParameters.a)" -type Highlight 

    "$(get-date) - SomeReturnValue"
}

if($LogName){
    $logname = Initialize-Logging -mergeto $LogName
}
else{
    $global:logname = Initialize-Logging -title "Dummy Module is imported directly" -Verbose -Path $env:TEMP
}
