$trace = Trace-Script -ScriptBlock { 
    & "$PSScriptRoot/Write-Avocado.ps1" 
}

$trace.Top50SelfDuration |
    Select-Object -First 5 |
    Format-Table SelfPercent, SelfDuration, HitCount, File, Line, Text 

