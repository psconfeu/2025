<#
    Author : Tibor Soós
    Version: 1.0.0 (2025.06.14)
#>
param(
    [Parameter()][ValidateSet('00VerboseErrorWarning', '01Silent', '02Unhandled', '03TerminateMain','04TerminateFunction','05ProgressBar', 
        '06OutputObject', '07OutputFile', '08AlternateLogFile', '09ModuleLogging', '10ModuleLoggingWithAlternateLog', '11SimulateRunbook')] $LogScenario
)

function SubFunction {
    New-LogEntry "This is a highlighted entry from a function" -type Highlight

    if($LogScenario -match 'Module'){
        New-LogEntry "value of `$a : $a" -type Warning
    }

    if($LogScenario -match 'Verbose|Silent'){
        New-LogEntry "Indented entry from a function" -indentlevel 1
        New-LogEntry "This is an absolute 0 indent" -indentlevel 0 -useabsoluteindent
    }

    if($LogScenario -match 'TerminateFunction'){
        New-LogEntry "Serious issue in a function" -type Terminate
    }

    "This is some output"
}

<#
psedit "C:\Users\$env:USERNAME\OneDrive\Dokumentumok\WindowsPowerShell\Modules\DummyModule\DummyModule.psm1"
psedit "C:\Users\$env:USERNAME\OneDrive\Dokumentumok\WindowsPowerShell\Modules\ScriptTools\1.0.0\ScriptTools.psm1"
cd C:\Users\$env:USERNAME\OneDrive\PS\PSConfEU
dir .\logs | remove-item

$psISE.CurrentPowerShellTab.Files.RemoveAt(0)

10..20 | foreach-object{
    $newfile = new-item -path .\Logs -Name "DemoLog.ps1-202501$_.log" -ItemType File
    $newfile.LastWriteTime = [datetime] "2025.01.$_"
}

ii .\logs

Import-Module ScriptTools -Force
Import-Module DummyModule -Force

cls
#>

######################################################################################
#
# Body
# 
######################################################################################

Import-Module ScriptTools -Force

if($LogScenario -match 'AlternateLog'){
    $logname = Initialize-Logging -title "Logging Demo" -Verbose -BySeconds
}
elseif($LogScenario -match 'SimulateRunbook'){
    $logname = Initialize-Logging -title "Logging Demo" -Verbose -simulateRunbook
}
elseif($LogScenario -match 'Silent'){
    $logname = Initialize-Logging -title "Logging Demo"
}
else{
    $logname = Initialize-Logging -title "Logging Demo" -Verbose
}

Import-Module DummyModule -Force -ArgumentList $logname

$a = "VARIABLE-DEFINED-IN-SCRIPT"
$PSBoundParameters.a = $a

New-LogEntry "This is a simple info"

if($LogScenario -match 'TerminateMain'){
    New-LogEntry "Some serious issue" -type Terminate -exitcode 33
}

if($LogScenario -match 'Verbose|Silent'){
    New-LogEntry "This is a detail entry" -indentlevel 1 -Verbose

    New-LogEntry "Call stack item of the script:"
    (Get-PSCallStack)[0] | Format-LogStringList | New-LogEntry -IndentLevel 1
}

if($LogScenario -match 'Warning|SimulateRunbook'){
    New-LogEntry "This is a warning" -type Warning
}

if($LogScenario -match 'Error|SimulateRunbook'){
    New-LogEntry "This is some error" -type Error
}

if($LogScenario -match 'Unhandled'){
    Remove-Item -Path c:\nonexistent\dummy.txt
}

SubFunction

if($LogScenario -match 'Verbose|Silent|SimulateRunbook'){
    New-LogEntry "This is a highlighted entry" -type Highlight
}

if($LogScenario -match 'ProgressBar|SimulateRunbook'){
    $array = 1..200 | ForEach-Object {Get-Random -Minimum 1 -Maximum 10000}

    foreach($a in $array){
        # Write-Progress -Activity "Processing element $a..." -Status "Processing..." -PercentComplete ($x/100) -SecondsRemaining ($calculate.the.seconds) -
        Write-LogProgress -inputarray $array -action "Processing element $a..." -progresslogfirst 10
        Start-Sleep -Milliseconds 60
    }
}

$object1 = [pscustomobject] @{
                One = 1
                Two = "Some text"
                Three = get-date
                Four = 11,22,33,44,55
                Empty = $null
                Secret = "This is a password"
            }

$object2 = [pscustomobject] @{
                One = 2
                Two = "Some text 2"
                Three = get-date
                Four = 19,28,37,46
                Empty = $null
                Secret = "This is another password"
            }

if($LogScenario -match 'OutputObject'){
    New-LogEntry "List view:"
    $object1, $object2 | Format-LogStringList -divide -hideNulls -hideProperty Secret | New-LogEntry -indentlevel 1

    New-LogEntry "Table view:"
    $object1, $object2 | Format-LogStringTable -ExcludeProperty Secret | New-LogEntry -indentlevel 1
}

if($LogScenario -match 'OutputFile'){
    $csv = New-LogFile -name "exportdata.csv"
    New-LogEntry "Data is exported to '$csv'..."

    $object1, $object2 | Export-Csv -Path $csv -NoTypeInformation -Encoding Default
    psedit -filenames $csv
}

if($LogScenario -match "AlternateLog"){
    $mainLog = $logname

    $logname = Initialize-Logging -title "This is another log file" -name Item.log -datePart RITM1234567 -Verbose
    New-LogEntry "This is an entry in alternate log file" 
}

if($LogScenario -match 'ModuleLogging'){
    $result = Get-DMInfo
    New-LogEntry "Result of module function: $result"
}

if($LogScenario -match "AlternateLog"){
    New-LogFooter

    psedit $logging.$logname.logpath

    $logname = $mainLog
    $PSBoundParameters.logname = $logname # HERE'S THE KEY STEP FOR MODULE FUNCTIONS!!!!
    New-LogEntry "This is an entry in the main log again"
}

if($LogScenario -match 'SimulateRunbook'){
    Wait-Debugger
}

if($LogScenario -match 'AlternateLog'){
    if($LogScenario -match '^\d{2}AlternateLog'){
        Invoke-Item $logging.$logname.logfolder
        Wait-Debugger

        $file = $psISE.CurrentPowerShellTab.Files | Where-Object {$_.displayname -match '^Item-'}
        [void] $psISE.CurrentPowerShellTab.Files.Remove($file)
    }

    New-LogEntry "Normal exit from the script" -type Exit -ignorelog
}
else{
    New-LogEntry "Normal exit from the script" -type Exit
} 

Write-Host "This will never get executed, it's after the 'exit'" -ForegroundColor Yellow

