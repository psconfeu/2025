#region Logging
function Initialize-Logging {
[CmdletBinding()]
param(
    [string] $Title,
    [string] $Name,
    [string] $Path,
    # [hashtable[]] $additionalColumns,
    [string[]] $IgnoreCommand = "HandleError",
    [int]    $KeepDays = 60,
    [int]    $ProgressBarSec = 1,
    [int]    $ProgressLogFirst = 60,
    [int]    $ProgressLogMin   = 5,
    [string[]] $IgnoreLocation = ("ScriptTools", "ScriptBlock"),
    [string] $MergeTo,
    [string[]] $EmailNotification,
    [string] $SMTPServer,
    [switch] $BySeconds,
    [string] $DatePart,
    [switch] $SimulateRunbook
)
    if($MergeTo){
        return $MergeTo
    }

    (Get-Variable -Name Error -Scope global -ValueOnly).Clear()

    $cs = @(Get-PSCallStack)
    $scriptinvocation = $cs[1].InvocationInfo

    $version = "0.0.0"
    $releasedate = ""

    $additionalColumns = @(@{Name = "Function"; Rule = {$environmentInvocation.MyCommand.Name}; width = 26})

    if(($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug) -or ($MergeTo -and $global:logging.$MergeTo._DebugMode)){
        $additionalColumns += @{Name = "Module"; Rule = {$environmentInvocation.mycommand.Modulename}; width = 20}, 
                                @{Name = "Environment"; Rule = {$environmentInvocation.BoundParameters.cmdenvironment}}, 
                                @{Name = "Resource"; Rule = {$environmentInvocation.BoundParameters.resource}; width = 20},
                                @{Name = "ResourceID"; Rule = {$environmentInvocation.BoundParameters.resourceID}; width = 13}
    }

    if(Get-Member -InputObject $scriptinvocation.MyCommand -Name scriptcontents -ErrorAction Ignore){
        $scripttext = $scriptinvocation.MyCommand.scriptcontents
        $versionfound = $scripttext -match "Version\s*:\s*(?<version>\d+\.\d+(\.\d+)*)(\s*\((?<releasedate>\d{4}\.\d{2}\.\d{2})\))?"
        if($versionfound){
            $releasedate = $Matches.releasedate
            $version = $Matches.version
        }
    }
    
    $environment = $host.Name
    $UseOutput = $false

    if($SimulateRunbook){
        $Path = $env:TEMP
        $environment = 'Simulated Runbook'
        $BySeconds = $true
        $UseOutput = $true
    }
    elseif($env:AZUREPS_HOST_ENVIRONMENT -eq 'AzureAutomation'){
        $Path = $env:TEMP
        $environment = $env:AZUREPS_HOST_ENVIRONMENT
        $BySeconds = $true
        $UseOutput = $true
    }
    elseif($host.name -eq 'Default Host'){
        $Path = $env:TEMP
        $environment = "Hybrid Worker"
        $BySeconds = $true
        $UseOutput = $true
    }
    elseif(!$Path){
        if($scriptinvocation.MyCommand.path){
            $Path = Split-Path $scriptinvocation.MyCommand.path
        }
        else{
            $Path = $env:TEMP
        }

        $Path = Join-Path $Path Logs
    }

    if($scriptinvocation.MyCommand.Name){
        $scriptname = $scriptinvocation.MyCommand.Name
    }
    else{
        $scriptname = "Interactive"
    }

    if($scriptinvocation.MyCommand.path){
        $scriptpath = Split-Path -Path $scriptinvocation.MyCommand.path
    }
    else{
        $scriptpath = "Interactive"
    }

    $columns = @('"DateTime"           ','"Line"  ','"Type"     ')
    if($additionalColumns){
        $columns += $additionalColumns | ForEach-Object {"{0,$(-([math]::max($_.width,$_.name.length)+2))}" -f """$($_.name)"""}
    }
    $columns += '"Message"'

    if(!$Name){
        $LogName = "$($scriptname).log"
    }
    else{
        $LogName = $Name
    }
    
    if(!$global:logging -or $global:logging -isnot [hashtable]){
        $global:logging = @{}
    }

    $logFile = New-LogFile -name $LogName -path $Path -keepdays $KeepDays -logname $LogName -byseconds:$BySeconds -datepart $DatePart

    $cs[1].InvocationInfo.BoundParameters.logname = $logFile.name

    $parentprocess = $null
    $myprocess = Get-CimInstance -ClassName Win32_process -Filter "ProcessID = '$PID'" -Verbose:$false
    if($myprocess.ParentProcessId){
        $parentprocess = Get-CimInstance -ClassName Win32_process -Filter "ProcessID = '$($myprocess.ParentProcessId)'" -Verbose:$false
    }

    $global:logging.$($logFile.Key) = [pscustomobject] @{
            Title = $Title
            ScriptName = $scriptname
            ScriptPath = $scriptpath
            ScriptVersion = "$version $(if($releasedate){"($releasedate)"})"
            RunBy = "$env:USERDOMAIN\$env:USERNAME"
            IsAdministrator = Get-LogIsAdministrator
            Computer = $env:COMPUTERNAME
            LogPath = $logFile.fullname
            LogFolder = $logFile.DirectoryName
            LogStart  = Get-Date
            Environment = $environment
            _IndentOffset   = $cs.count
            _LastLine       = ""
            _WarningsLogged = 0
            _ErrorsLogged   = 0
            _UnhandledErrors = 0
            _VerboseMode    = if($PSBoundParameters.ContainsKey('verbose')){$PSBoundParameters.verbose}else{$false}
            _DebugMode      = $PSBoundParameters.Debug
            _Progress = [PSCustomObject] @{
                    ArrayID = 0
                    Counter = 0
                    Start   = $null
                    BarSec  = $ProgressBarSec
                    BarNext  = $null
                    LogFirst = $ProgressLogFirst
                    LogNext  = $null
                    LogMin   = $ProgressLogMin
                }
            _AdditionalColumns = $additionalColumns
            _IgnoreCommand  = $IgnoreCommand
            _ignoreLocation = $IgnoreLocation
            _email          = $EmailNotification
            _smtpserver     = $SMTPServer
            _baseindent     = 0
            _LogCache       = [System.Collections.Queue] @()
            _MaxCacheSize   = 1000
            _UseOutput      = $UseOutput
            _parentProcess  = $parentprocess
        }

    if($logFile.new){
        Set-Content -Path $logFile.Fullname -Value ($columns -join ",")
    }

    $global:logging.$($logFile.Key) | Format-LogStringList -excludeProperty _* | FormatBorder | New-LogEntry -type Header -logname $logFile.key

    if($scriptinvocation.BoundParameters.count){
        [PSCustomObject][hashtable]$scriptinvocation.BoundParameters | Format-LogStringList -excludeproperty LogName | 
            FormatBorder -title "Bound Parameters:" -indentlevel 1 |
                New-LogEntry -indentlevel 1 -logname $logFile.key
    }

    if($ScriptImplicitParams = Get-Variable -Name ScriptImplicitParams -Scope Global -ErrorAction Ignore -ValueOnly){
        [PSCustomObject] $ScriptImplicitParams | Format-LogStringList | 
            FormatBorder -title "Parameters with defaults:" -indentlevel 1 |
                New-LogEntry -indentlevel 1 -logname $logFile.key
    }

    $logFile.DelayedLogEntries | New-LogEntry -indentlevel 1

    return $logFile.key
}

function GetLogName {
    if($global:logging -and $global:logging -is [hashtable] -and $global:logging.Keys.Count -eq 1){
        $LogName = $global:logging.Keys | Select-Object -First 1 
    }

    $cs = @(Get-PSCallStack | Where-Object {$_.Location -ne '<No file>'})
    $realstack = @($cs | Where-Object {$_.ScriptName -ne $cs[0].ScriptName})
    Set-Variable -Name logcallstack -Value $cs -Scope 1
    Set-Variable -Name logrealdepth -Value $realstack.Count -Scope 1

    if(!$LogName){
        for($i = 1; $i -lt $cs.Length; $i++){
            if(!$LogName -and $cs[$i].InvocationInfo.BoundParameters.ContainsKey('logname')){
                $LogName = $cs[$i].InvocationInfo.BoundParameters.logname            
                break       
            }
        }
    }

    if(!$LogName -and $global:logname){
        $LogName = $global:logname
    }

    $LogName
}

function Write-LogProgress {
[cmdletbinding()]
    param(
        $InputArray,
        [string][Alias('Action')] $Activity,
        [int] $Percent,
        [string] $LogName,
        [int] $ProgressLogFirst
    )

    if(!$inputarray -or !$inputarray.count){
        return
    }

    if($PSBoundParameters.ContainsKey('logname') -and !$LogName){
        return
    }

    $LogName = GetLogName

    if(!$LogName -or !$global:logging.ContainsKey($LogName)){
        $LogName = $null
        if($env:AZUREPS_HOST_ENVIRONMENT -eq 'AzureAutomation'){
            Write-Error "Logname '$LogName' is not valid"
            $global:Error.RemoveAt(0)
        }
        else{
            Write-Host "Logname '$LogName' is not valid" -ForegroundColor Red
        }
        return
    }

    if($ProgressLogFirst -eq 0){
        $ProgressLogFirst = $global:logging.$LogName._Progress.LogFirst
    }

    if($inputarray.gethashcode() -ne $global:logging.$LogName._Progress.ArrayID){
        $global:logging.$LogName._Progress.ArrayID = $inputarray.gethashcode()
        $global:logging.$LogName._Progress.Start   = get-date
        $global:logging.$LogName._Progress.BarNext = get-date
        $global:logging.$LogName._Progress.Counter = 0
        $global:logging.$LogName._Progress.LogNext = (get-date).AddSeconds($ProgressLogFirst)
    }

    if((Get-Date) -ge $global:logging.$LogName._Progress.BarNext -and ($global:logging.$LogName._VerboseMode -or $PSBoundParameters.verbose)){
        if(!$PSBoundParameters.ContainsKey('percent')){
            $percent = $global:logging.$LogName._Progress.Counter / $inputarray.count * 100
        }

        if($percent -gt 100){
            $percent = 100
        }

        if($global:logging.$LogName._Progress.Counter -eq 0){
            $timeleft = [int]::MaxValue
        }
        else{
            $timeleft = ((Get-Date) - $global:logging.$LogName._Progress.Start).totalseconds * ($inputarray.Count - $global:logging.$LogName._Progress.Counter) / $global:logging.$LogName._Progress.Counter
        }

        $done = "{0,$("$($inputarray.Count)".Length)}" -f $global:logging.$LogName._Progress.Counter
        $left = "{0,$("$($inputarray.Count)".Length)}" -f ($inputarray.Count - $global:logging.$LogName._Progress.Counter)
        Write-Progress -Activity $Activity -Status "All: $($inputarray.Count) Done: $done Left: $left" -PercentComplete $percent -SecondsRemaining $timeleft
        $global:logging.$LogName._Progress.BarNext = (get-date).AddSeconds($global:logging.$LogName._Progress.BarSec)
    }

    if((Get-Date) -ge $global:logging.$LogName._Progress.LogNext){
        if($global:logging.$LogName._Progress.Counter -eq 0){
            $timeleft = [int]::MaxValue
        }
        else{
            $timeleft = [int] (((Get-Date) - $global:logging.$LogName._Progress.Start).totalseconds * ($inputarray.Count - $global:logging.$LogName._Progress.Counter) / $global:logging.$LogName._Progress.Counter)
        }

        $timeleft = [timespan]::FromSeconds($timeleft).tostring()

        $done = "{0,$("$($inputarray.Count)".Length)}" -f $global:logging.$LogName._Progress.Counter
        $left = "{0,$("$($inputarray.Count)".Length)}" -f ($inputarray.Count - $global:logging.$LogName._Progress.Counter)
        
        New-LogEntry -message "All: $($inputarray.Count) Done: $done Left: $left Estimated time left: $timeleft" -type Progress

        $global:logging.$LogName._Progress.LogNext = (get-date).AddMinutes($global:logging.$LogName._Progress.LogMin)
    }

    $global:logging.$LogName._Progress.Counter++
}

function New-LogFile {
param(
    [string] $Name,
    [string] $Path,
    [int]    $KeepDays = 60,
    [switch] $BySeconds,
    [switch] $Overwrite,
    [string] $DatePart
)
    if(!$Path){
        $LogName = GetLogName

        $Path = $global:logging.$LogName.LogFolder
    }
    
    if(!(Test-Path -Path $Path -PathType Container)){
        [void] (New-Item -Path $Path -ItemType Directory -ErrorAction Stop)
    }
    
    if($BySeconds){
        $DatePart = Get-Date -Format 'yyyyMMddHHmmss'
    }
    elseif(!$DatePart){
        $DatePart = Get-Date -Format 'yyyyMMdd'
    }

    $filename = $Name -replace "(?=\.(?!.*?\.))", "-$DatePart"
    $searchname = $Name -replace "(?=\.(?!.*?\.))", "-*"

    if($PSBoundParameters.ContainsKey('datepart')){
        $key = $filename
    }
    else{
        $key = $Name
    }

    $delayedLogEntries = @()
    if($KeepDays){
        Get-ChildItem -Path $Path -Filter $searchname | Where-Object {((get-date) - $_.LastWriteTime).totaldays -gt $KeepDays} |
            ForEach-Object {
                if(!$LogName -or !$global.logging.$LogName){
                    $delayedLogEntries += "Removing obsolete file: '$($_.FullName)'"
                }
                else{
                    New-LogEntry -message "Removing obsolete file: '$($_.FullName)'" -indentlevel 1
                }
                Remove-Item -Path $_.FullName
            }
    }

    if($Overwrite -or (!(Test-Path -Path (Join-Path -Path $Path -ChildPath $filename)))){
        $file = New-Item -Path $Path -Name $filename -ItemType file -Force:$Overwrite | Add-Member -MemberType NoteProperty -Name New -Value $true -PassThru 
    }
    else{
        $file = Get-Item -Path (Join-Path -Path $Path -ChildPath $filename) | Add-Member -MemberType NoteProperty -Name New -Value $false -PassThru
    }

    Add-Member -InputObject $file -MemberType NoteProperty -Name Key -Value $key -PassThru | Add-Member -MemberType NoteProperty -Name DelayedLogEntries -Value $delayedLogEntries -PassThru
}

function FormatBorder {
param(
    [Parameter(ValueFromPipeline=$true)][string[]]$Strings,
    [string] $Title,
    [int] $IndentLevel
)
begin{
    $lines = @()
    if($Title){
        $lines += $Title
    }
}
process{
    foreach($string in $Strings){
        $lines += " " * $IndentLevel * 4 + $string
    }
}
end{
    $longest = $lines | Sort-Object -Property Length -Descending | Select-Object -First 1 -ExpandProperty Length
    "#" * ($longest + 4)
    foreach($line in $lines){
        "# $($line.padright($longest)) #"
    }
    "#" * ($longest + 4)
}
}

function Format-LogStringList {
param(
    [Parameter(ValueFromPipeline = $true)]$Object,
    [string[]] $Property = "*",
    [string[]] $ExcludeProperty = $null,
    [switch] $Divide,
    [switch] $HideNulls,
    [int] $IndentLevel,
    [switch] $Sort,
    $Sortby,
    [switch] $Bordered,
    [string[]] $HideProperty
)
begin {
    $lines = @()
}
process{
    
    $selecttedprops = @()
    $longest = 0

    foreach($p in $Object.psobject.Properties){
        if($ExcludeProperty | Where-Object {$p.name -like $_} | Select-Object -First 1){
            continue
        }
        if(($Property | Where-Object {$p.name -like $_} | Select-Object -First 1) -and (!$HideNulls -or $p.value)){
            $selecttedprops += $p

            if($p.name.length -gt $longest){
                $longest = $p.name.length + 1
            }
        }
    }

    if($Object -is [string]){
        $lines += " " * $IndentLevel * 4 + $Object
    }
    elseif($selecttedprops){
        if($Sort){
            if(!$Sortby){
                $Sortproperty = "name"
            }
            else{
                $Sortproperty = $Sortby
            }
        }
        else{
            $Sortproperty = "dummy"
        }

        foreach($sp in ($selecttedprops | Sort-Object -Property $Sortproperty -Debug:$false)){
            if($sp.value -as [string] -and ($HideProperty | Where-Object {$sp.name -like $_})){
                $Value = '*' * ([string]$sp.value).length
            }
            else{
                $Value = $sp.value
            }
            $lines += " " * $IndentLevel * 4 + $sp.name.padright($longest) + ": " + $Value
        }
    }
    if($Divide){
        $lines += "-" * 92
    }
}
end{
    if($Bordered){
        $lines | FormatBorder
    }
    else{
        $lines
    }
}
}

function Format-LogStringTable {
param(
    [Parameter(ValueFromPipeline = $true)]$Object,
    [object[]] $Property = "*",
    [string[]] $ExcludeProperty = $null,
    [switch] $Bordered
)
    $ftsplatting = @{}

    if($Property){
        $ftsplatting.Property = $Property
    }

    if($ExcludeProperty){
        $ftsplatting.ExcludeProperty = $ExcludeProperty
    }

    $lines = ($input | Select-Object @ftsplatting | Format-Table -AutoSize | Out-String) -split "\r\n" | 
        Where-Object {$_ -and $_.trim()}

    if($Bordered){
        $lines | FormatBorder
    }
    else{
        $lines
    }
}

function Write-LogUnhandeldErrors {
    $scripterror = Get-Variable -Name Error -Scope Global -ValueOnly

    if($scripterror){
        $err2 = $scripterror.clone()
        $err2.reverse()
        $scripterror.clear()
        foreach($e in $err2){
            New-LogEntry -message "$($e.ScriptStackTrace): $($e.Exception.Message)" -type Unhandled
            $global:logging.$LogName._UnhandledErrors++
        }
    }
}

function Add-LogTextWithRetry {
[cmdletbinding()]
param(
    [string] $Path,
    [Parameter(ValueFromPipeline = $true)][string[]] $Text,
    [ValidateScript( { $_ -is [System.Text.Encoding] })] $Encoding = [System.Text.Encoding]::UTF8,
    [int] $Timeout = 1,
    [switch] $Force
)   
begin{
    $retry = $true
    $start = Get-Date
    $h = $null
    do {
        try {
            $locked = $false
            $h = [io.file]::AppendText($Path)
        } 
        catch {
            $global:Error.Clear()
            if ($_.Exception.InnerException -and $_.Exception.InnerException.HResult -eq -2147024864) {
                Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 500)
                $locked = $true
            } 
            else {
                $retry = $false
                $Force = $true
            }
        }
        if (((Get-Date) - $start).totalseconds -gt $Timeout) {
            $retry = $false
        }
    }while ((!$h -or !$h.BaseStream) -and $retry)

    if ($h -and $h.BaseStream -and $global:logging.$LogName._LogCache.count) {
        while ($global:logging.$LogName._LogCache.Count) {
            $cline = $global:logging.$LogName._LogCache.dequeue()
            $h.Writeline($cline)
        }
    }
}
process{
    foreach($line in $Text){
        if (!$h -or !$h.BaseStream) {            
            if ($Force -or !$locked) {
                throw "LogAppendText error"
            } 
            else {
                $global:logging.$LogName._LogCache.EnQueue($line)
                if($global:logging.$LogName._LogCache.Count -gt $global:logging.$LogName._MaxCacheSize){
                    $tempfile = Join-Path -Path (Split-Path $Path) -ChildPath "_Templog-$(get-date -Format 'yyyy-MM-dd-HH-mm-ss-fffffff').log" 
                    $global:logging.$LogName._LogCache | Set-Content -Path $tempfile -Encoding ($Encoding.EncodingName -replace 'US-')
                    $global:logging.$LogName._LogCache.Clear()
                }
            }
        }
        else{
            $h.Writeline($line)
        }
    }
}
end{
    if($h){
        $h.Close()
    }
}
}

function New-LogEntry {
[cmdletbinding()]
param(
    [Parameter(ValueFromPipeline = $true)] [string] $Message,
    [Parameter()][ValidateSet('Info', 'Highlight', 'Warning', 'Error', 'Exit', 'Terminate', 'Unhandled', 'Progress', 'Debug', 'Header', 'Negative')]$Type = 'Info',
    [int] $IndentLevel,
    [switch] $UseAbsoluteIndent,
    [switch] $NoNewLine,
    [switch] $DisplayOnly,
    [string] $LogName,
    [switch] $IgnoreLog,
    [int] $ExitCode
)
begin{
    $LogName = GetLogName

    $relativelevel = 0

    $localverbose = $null

    for($i = 1; $i -lt $logcallstack.Length; $i++){
        if(!$relativelevel -and $logcallstack[$i].ScriptName -ne $logcallstack[0].ScriptName -and (!$LogName -or $logcallstack[$i].Command -notin $global:logging.$LogName._IgnoreCommand)){
            $relativelevel = $i
        }

        if($null -eq $localverbose -and ($VerbosePreference -notin 'SilentlyContinue', 'Ignore' -or $logcallstack[$i].InvocationInfo.BoundParameters.ContainsKey('Verbose'))){
            $localverbose = $logcallstack[$i].InvocationInfo.BoundParameters.Verbose
        }
    }

    if(!$LogName){
        $LogName = $null
        if($env:AZUREPS_HOST_ENVIRONMENT -eq 'AzureAutomation' -or $host.name -eq 'Default Host'){
            Write-Error "Logname '$LogName' is not valid"
            $global:Error.RemoveAt(0)
        }
        else{
            Write-Host "Logname '$LogName' is not valid" -ForegroundColor Red
        }
    }

    if($null -eq $localverbose){
        $localverbose = $global:logging.$LogName._VerboseMode
    }

    $environmentInvocation = $logcallstack | Where-Object {$_.Location -notmatch ($global:logging.$LogName._IgnoreLocation -join "|") -and $_.command -notmatch ($global:logging.$LogName._IgnoreCommand -join "|")} | Select-Object -First 1 -ExpandProperty InvocationInfo

    $baseindent = [math]::Max($logrealdepth - 1, 0)

    if($IndentLevel){
        $global:logging.$LogName._BaseIndent = $IndentLevel
    }
    else{
        $global:logging.$LogName._BaseIndent = $baseindent
    }

    if(!$UseAbsoluteIndent){
        $IndentLevel = $IndentLevel + $baseindent
    }

    $linenumber = $logcallstack[$relativelevel].ScriptLineNumber
    
    switch($Type){
        'Info'           {$param = @{ForegroundColor = "Gray"}}
        'Highlight'      {$param = @{ForegroundColor = "Green"}}
        'Header'         {$param = @{ForegroundColor = "Green"}}
        'Debug'          {$param = @{ForegroundColor = "Cyan"; BackgroundColor = 'DarkGray'}}
        'Warning'        {$param = @{ForegroundColor = "Yellow"; BackgroundColor = 'DarkGray'}; $global:logging.$LogName._WarningsLogged++}
        'Error'          {$param = @{ForegroundColor = "Red"}; $global:logging.$LogName._ErrorsLogged++}
        'Negative'       {$param = @{ForegroundColor = "Red"}}
        'Exit'           {$param = @{ForegroundColor = "Green"}}
        'Terminate'      {$param = @{ForegroundColor = "Red"; BackgroundColor = 'Black'}; $global:logging.$LogName._ErrorsLogged++}
        'Unhandled'      {$param = @{ForegroundColor = "Red"; BackgroundColor = 'DarkGray'}; $global:logging.$LogName._ErrorsLogged++}
        'Progress'       {$param = @{ForegroundColor = "Magenta"}}
    }

    if($Type -ne 'Unhandled'){
        Write-LogUnhandeldErrors
    }
}
process{
    if($LogName){
        if($global:logging.$LogName._LastLine){
            $line = " $Message"
        }
        else{
            $line = "[$(Get-Date -Format 'yyyy.MM.dd HH:mm:ss')],[$(([string]$linenumber).PadLeft(6))],[$($Type.toupper().padright(9))]"
            if($global:logging.$LogName._additionalColumns){
                foreach($c in $global:logging.$LogName._additionalColumns){
                    $line += ",[{0,$(-([math]::max($c.width,$c.name.length)))}]" -f ($c.Rule.GetNewClosure().invoke()[0])
                }
            }
            $line += ", »$(" " *$IndentLevel * 4)$Message"
        }

        if($NoNewLine -or $global:logging.$LogName._LastLine){
            $global:logging.$LogName._LastLine += $line
        }

        if($LogName -and !$NoNewLine -and !$DisplayOnly){
            if($global:logging.$LogName._LastLine){
                #Add-Content -path $global:logging.$LogName.LogPath -Value $global:logging.$LogName._LastLine
                Add-LogTextWithRetry -path $global:logging.$LogName.LogPath -text $global:logging.$LogName._LastLine
                $global:logging.$LogName._LastLine = ""
            }
            else{
                #Add-Content -path $global:logging.$LogName.LogPath -Value $line
                Add-LogTextWithRetry -path $global:logging.$LogName.LogPath -text $line
            }
        }
    }

    if($DisplayOnly -or $localverbose -or $Type -in 'Debug', 'Error', 'Terminate', 'Unhandled', 'Negative', 'Warning'){
        if($global:logging.$LogName._UseOutput){
            if($Type -in 'Error', 'Terminate', 'Unhandled'){
                Write-Error $line
                $global:Error.RemoveAt(0)
            }
            elseif($Type -eq 'Warning'){
                Write-Warning $line
            }
            elseif($Type -match '^(Progress|Highlight)$' -and @($logcallstack | Where-Object {$_.ScriptName -ne $logcallstack[0].ScriptName}).Count -le 1){
                Write-Output $line
            }
        }
        else{
            Write-Host -Object $line @param -NoNewline:$NoNewLine
        }
    }
}
end{
    if($Type -in 'Exit', 'Terminate'){
        if($LogName){
            
            New-LogFooter -logname $LogName

            if($null -eq $ExitCode -or $ExitCode -isnot [int]){
                if($global:logging.$LogName._ErrorsLogged){
                    $ExitCode = 1
                }
                elseif($global:logging.$LogName._WarningsLogged){
                    $ExitCode = 2
                }
                else{
                    $ExitCode = 0
                }
            }

            if(!$IgnoreLog){
                if($global:logging.$LogName._email -and $global:logging.$LogName._smtpserver){
                    $contents = ""
                    foreach($log in $global:logging.Keys){
                        if($global:logging.$log._ErrorsLogged){
                            $contents += (Get-Content $global:logging.$log.LogPath -Encoding utf8) -join "`r`n"
                            $contents += "`r`n" + "`r`n" + ("-" * 200) + "`r`n"
                            $global:logging.$log._ErrorsLogged = 0
                        }
                    }

                    if($contents){
                        Send-MailMessage  -SmtpServer $global:logging.$LogName._smtpserver -To $global:logging.$LogName._email -Subject "PAMaaS Error Logs - $(get-date -Format 'yyyy.MM.dd HH.mm.ss')" -From "$($global:logging.$LogName.ScriptName)@clearstream.com" -Body $contents -Encoding utf8
                    }
                }
            }
            else{
                Remove-Item -Path $global:logging.$LogName.LogPath
            }

            if($global:logging.$LogName._UseOutput){
                get-content -Path $global:logging.$LogName.LogPath -encoding utf8

                if($logrealdepth -lt 1 -and ($global:logging.$LogName._parentprocess.Name -in 'exporer.exe', 'WindowsTerminal.exe' -or $Host.Name -match 'ISE|Visual Studio')){
                    throw "$($Type)ing session with exit code $ExitCode"
                }
                else{
                    exit $ExitCode
                }
            }
            elseif($global:logging.$LogName.ScriptName -ne 'Interactive'){
                if($global:logging.$LogName._parentprocess.Name -in 'exporer.exe', 'WindowsTerminal.exe' -or $Host.Name -match 'ISE|Visual Studio'){
                    if($logrealdepth -lt 1){
                        throw "$($Type)ing session with exit code $ExitCode"
                    }
                    else{
                        exit $ExitCode
                    }
                }
                else{
                    [environment]::Exit($ExitCode)
                }
            }
        }

        if($logcallstack.count -le 3){
            return
        }
        else{
            throw "Interactive exit: $ExitCode"
        }
    }
}
}

function New-LogFooter {
param([string]$LogName)

    if($PSBoundParameters.ContainsKey('logname') -and !$LogName){
        return
    }

    $LogName = GetLogName

    if(!$LogName -or !$global:logging.ContainsKey($LogName)){
        $LogName = $null
        if($env:AZUREPS_HOST_ENVIRONMENT -eq 'AzureAutomation' -or $host.name -eq 'Default Host'){
            Write-Error "Logname '$LogName' is not valid"
            $global:Error.RemoveAt(0)
        }
        else{
            Write-Host "Logname '$LogName' is not valid" -ForegroundColor Red
        }
    }

    $seconds = [int] ((Get-Date) - $global:logging.$LogName.LogStart).totalseconds

    $footer =   "LogName       : $LogName",
                "Runtime       : $([timespan]::FromSeconds($seconds).tostring())",
                "ErrorsLogged  : $($global:logging.$LogName._ErrorsLogged)",
                "WarningsLogged: $($global:logging.$LogName._WarningsLogged)",
                "ParentProcess : $($global:logging.$LogName._parentprocess.name)"
    $footer | FormatBorder | New-LogEntry -type Header
}

function Search-LogEntries {
param(
    [string[]] $LogNames = $global:logging.Keys,
    [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)] [string[]] $LogPath,
    [scriptblock] $FilterScript,
    [switch] $AllDates,
    [AllowNull()] [string[]] $SortBy,
    [switch] $Descending
)
begin{
    if($LogPath){
        if($PSBoundParameters.ContainsKey('lognames')){
            $LogPath = Get-ChildItem -Path $LogPath -Include $LogNames -Recurse | Select-Object -ExpandProperty fullname
        }
        else{
            $LogPath = Get-ChildItem -Path $LogPath | Select-Object -ExpandProperty fullname
        }
    }
    elseif($LogNames){
        foreach($ln in $LogNames){
            $LogPath += $global:logging.$ln.LogPath
        }
    }
}
process{
    foreach($lp in $LogPath){
        if($AllDates){
            $lp = $lp -replace "-\d{8,}(?=\.[^\.]+$)", '*'
        }

        if($lp -notmatch "\.log"){
            $lp += "\*"
        }

        if(!$FilterScript){
             $FilterScript = {$_.Line -match '^\[\s*\d+\]$'}
        }
        else{
            $filterstring = [string] $FilterScript
            $filterstring += ' -and $_.Line -match ''^\[\s*\d+\]$'''
            $FilterScript = [scriptblock]::Create($filterstring)
        }

        if($SortBy){
            Get-Item -Path $lp -PipelineVariable p -ErrorAction Ignore | ForEach-Object {$_.fullname} | Import-Csv -Encoding Default | Where-Object -FilterScript $FilterScript | Sort-Object -Property $SortBy -Descending:$Descending | select-object -Property @{n="LogName"; e={$p.name}}, * | Format-LogStringTable
        }
        else{
            Get-Item -Path $lp -PipelineVariable p -ErrorAction Ignore | ForEach-Object {$_.fullname} | Import-Csv -Encoding Default | Where-Object -FilterScript $FilterScript | select-object -Property @{n="LogName"; e={$p.name}}, * | Format-LogStringTable
        }
    }
}
}

function Get-LogIsAdministrator {
    $u = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.principal.windowsprincipal -ArgumentList $u
    $IsAdministrator = !!(($principal.Identity.Groups | Select-Object -ExpandProperty value) -match "S-1-5-32-544")
    $IsAdministrator
}  
#endregion

#region Config management
function Import-Config {
param(
    [string[]]$PathsOrNames,
    [Parameter(Mandatory = $true)][hashtable] $PSConfig
)
    function ResolveDynamicData {
    param([hashtable] $Confighive, $parentkeys = @())
       
        foreach($key in ($Confighive.Clone().Keys | Sort-Object -Property {
                    if($_ -match '^Condition$'){"zz$($_)"}
                    elseif($_ -match 'ConfigAction'){"zzz$($_)"}
                    elseif($_ -match '^Conditional_'){"zzzz$($_)"}
                    else{"__$($_)"}
                }
            )
        ){
            if($Confighive.$key -is [hashtable]){
                ResolveDynamicData -confighive $Confighive.$key -parentkeys ($parentkeys + $key)
            }
            elseif($Confighive.$key -is [scriptblock] -and (!$Confighive.ContainsKey('Condition') -or $Confighive.Condition)){
                $errorhappened = $false
                $errorcount = $Error.Count
                try{
                    $Confighive.$key = &(& $Confighive.$key)
                }
                catch{
                    $errorhappened = $true
                }

                if($errorhappened -or $errorcount -gt $error.Count){
                    throw "Configuration parsing error"
                }
            }
        }
    }

    function MergeHives {
        param(
            [hashtable] $hive,
            [hashtable] $target = $PSConfig
        )

        foreach($h in $hive.Clone().Getenumerator()){
            if($h.key -match '^Condition|^ConfigAction$'){
                continue
            }
            elseif($h.value -isnot [hashtable]){
                $target.($h.key) = $h.value
            }
            elseif(!$target.ContainsKey($h.key)){
                if($h.value.containskey('ConfigAction')){
                    $h.value.remove('ConfigAction')
                }
                
                $target.($h.key) = $h.value
            }
            else{
                try{
                    MergeHives -hive $h.value -target $target.($h.key)
                }
                catch{
                }
            }
        }
    }
    
    if($null -eq $PSConfig){
        $PSConfig = @{}
    }

    $scriptinvocation = (Get-PSCallStack)[1].InvocationInfo

    if($scriptinvocation.mycommand.path -match "\\\d+\.\d+\.\d+\\.*?psm1$"){
        $defaultconfig = "$($scriptinvocation.mycommand.path -replace "\.psm1$" -replace "\\\d+\.\d+\.\d+\\(?!.*?\\)","\Config\").psd1"
    }
    elseif($scriptinvocation.mycommand.path -match "\\.*?psm1$"){
        $defaultconfig = "$($scriptinvocation.mycommand.path -replace "\.psm1$" -replace "\\(?!.*?\\)","\Config\").psd1"
    }
    else{
        $defaultconfig = "$($scriptinvocation.mycommand.path -replace "\\(?!.*?\\)","\Config\").psd1"
    }

    if(!$PathsOrNames -and !(test-path -path $defaultconfig)){
        if(get-module -Name "PSConfigs" -ErrorAction Ignore -ListAvailable){
            Import-Module -Name PSConfigs -Force
            $defaultconfig = Get-PSConfigs -ScriptName $scriptinvocation.MyCommand.Name
        }
    }

    if($PathsOrNames -notcontains $defaultconfig -and (Test-Path $defaultconfig)){
        $PathsOrNames = @($defaultconfig) + $PathsOrNames | Where-Object {$_}
    }

    foreach($Path in $PathsOrNames){
        if($Path -notmatch "^\w:|^\."){
            $Path = Join-Path (split-path $scriptinvocation.mycommand.path) "\Config\$Path"
        }

        if(!(Test-Path -Path $Path)){
            Write-Error "No config file was found at '$Path'"
            continue
        }

        $Config = Import-PowerShellDataFile -Path $Path

        ResolveDynamicData -confighive $Config

        $ConfigClone = $Config.Clone()

        foreach($key in ($ConfigClone.keys -notmatch '^Condition' | Sort-Object)){
            MergeHives -hive $Config
        }

        foreach($key in ($ConfigClone.keys -match '^Conditional_' | Sort-Object)){
            if($ConfigClone.$key.condition){
                MergeHives -hive $Config.$key
            }
        }
    }
}

function Expand-Config {
    param($Config, $Path = "PSConfig")
    
    if(!$Config -or ($Config -is [hashtable] -and $Config.Keys.Count -eq 0)){
        return
    }
    elseif($Config -isnot [hashtable]){
        foreach($eelement in $Config){
            [pscustomobject] @{
                    Path = $Path
                    Value = $element
                }
        }
        return
    }
    
    foreach($key in $Config.Keys){
        if($Config.$key -is [hashtable]){
            Expand-Config -config $Config.$key -path ($Path + "." + $key)
        }
        else{
            foreach($element in $Config.$key){
                Expand-Config -config $element -path ($Path + "." + $key)
            }
        }
    }
}
#endregion

#region Miscellaneous functions
function New-DynamicParameter {
param(
    [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Mandatory = $true)] [string] $Name,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [type]   $Type,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [string[]] $ParameterSetName ="Default",
    [Parameter(ValueFromPipelineByPropertyName = $true)] $Mandatory,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [scriptblock] $ValidationSet,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [switch] $ValueFromPipeline,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [switch] $ValueFromPipelineByPropertyName,
    [Parameter(ValueFromPipelineByPropertyName = $true)] $DefaultValue,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [scriptblock] $Condition,
    [Parameter(ValueFromPipelineByPropertyName = $true)] [string[]] $Aliases,
    [int] $StartPosition = 0
)
begin{
    $paramDictionary = new-object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $position = $StartPosition
}
process{
    if($null -eq $Condition -or (&$Condition)){
        $attributeCollection = new-object -TypeName System.Collections.ObjectModel.Collection[Attribute]

        foreach($psn in $ParameterSetName){
            $attribute = new-object -TypeName System.Management.Automation.ParameterAttribute
            $attribute.ParameterSetName = $psn
            if($PSBoundParameters.ContainsKey('startposition')){
                $attribute.Position = $position
                $position++
            }
            if($Mandatory -is [scriptblock]){
                $attribute.Mandatory = &$Mandatory
            }
            else{
                $attribute.Mandatory = $Mandatory
            }
            $attribute.ValueFromPipeline = $ValueFromPipeline
            $attribute.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName

            $attributeCollection.Add($attribute)
        }

        if($ValidationSet){
            $vsa = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList (&$ValidationSet)
            $attribute.HelpMessage = "Possible values: $((&$ValidationSet) -join ', ')"
            $attributeCollection.Add($vsa)           
        }

        if($Aliases){
            $alias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList $Aliases
            $attributeCollection.Add($alias)           
        }

        $param = new-object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList $Name, $Type, $attributeCollection
        
        $global:psb = $PSBoundParameters # defined for troubleshooting
        if($PSBoundParameters.ContainsKey('defaultValue') -and $null -ne $DefaultValue){
            $si = Get-PSCallStack
            if($DefaultValue -is [scriptblock]){
                $param.Value = &$DefaultValue
                $si[1].InvocationInfo.BoundParameters.$Name = $param.Value
            }
            else{
                $param.Value = $DefaultValue
                $si[1].InvocationInfo.BoundParameters.$Name = $DefaultValue
            }
        }
        $paramDictionary.Add($Name, $param)
    }    
}
end{
    $paramDictionary
}
}

function Search-Script {
param(
    [string] $Pattern,
    [string] $Path,
    [string[]] $Extension = ("ps1", "psm1"),
    [string[]] $Exclude = "wxyz",
    [switch] $SortByDate,
    [switch] $CaseSensitive
)
    if($Extension -ne "*"){
        $include = $Extension | ForEach-Object {$_ -replace "^(\*)?(\.)?","*." }
    }
    $Exclude = $Exclude | ForEach-Object {$_ -replace "^(\*)?(\.)?","*." }
    
    $Sortparam = "Path", "LineNumber"
    
    if($SortByDate){
        $Sortparam = @("LastWriteTime") + $Sortparam
    }

    $selectstringsplatting = @{}
    if($CaseSensitive){
        $selectstringsplatting.CaseSensitive = $true
    }

    Get-ChildItem -Path $Path -Include $include -Exclude $Exclude -Recurse |
        Select-String -Pattern $Pattern @selectstringsplatting |
            Select-Object -Property Path, @{n="LastWriteTime"; e = {(get-item -Path $_.Path).LastWriteTime}}, LineNumber, Line |
                Sort-Object -Property $Sortparam
}
#endregion

#region Property management
function Update-Property {
[cmdletbinding()]
param(
    [psobject] $Object,
    [string]   $PropName,
    [psobject] $Value = 1,
    [switch]   $PassThru,
    [switch]   $Force
)
    if($null -eq $Object){
        Write-Error "No object - update propery"        
        return
    }

    if($Object -is [hashtable] -and !$Object.containskey($PropName)){
        $Object.$PropName = $Value
    }
    elseif($Object -isnot [hashtable] -and $Object.psobject.Properties.Name -notcontains $PropName){
        Add-Member -InputObject $Object -MemberType NoteProperty -Name $PropName -Value $Value
    }
    elseif($Force){
        $Object.$PropName = $Value
    }
    elseif($Object.$PropName -is [int] -and $Value -is [int]){
        $Object.$PropName += $Value
    }
    elseif($Object.$PropName -is [string]){
        if($Value -ne $Object.$PropName){
            $Object.$PropName = @($Object.$PropName) + $Value
        }
    }
    elseif($Object.$PropName -is [collections.ilist]){
        if($Object.$PropName -is [collections.ilist] -and $Object.$PropName.count -gt 0 -and $Object.$PropName[0] -is [hashtable]){
            if($Value -is [collections.ilist] -and $Value.count -gt 0 -and $Value[0] -is [hashtable]){
                $existingKeys = $Object.$PropName | ForEach-Object {$_.Keys}

                if($existingKeys -notcontains ($Value.keys | Select-Object -First 1)){
                    $Object.$PropName += $Value
                }
                else{                    
                    $equalfound = $false
                    foreach($v in $Object.$PropName){
                        $difffound = $false
                        foreach($k in $v.keys){
                            if($v.$k -ne $Value[0].$k){
                                $difffound = $true
                                break
                            }
                        }
                        if(!$difffound){
                            $equalfound = $true
                            break
                        }
                    }
                    
                    if(!$equalfound){
                        $Object.$PropName += $Value
                    }
                }
            }
        }
        else{
            foreach($v in $Value){
                if($Object.$PropName -notcontains $v){
                    $Object.$PropName += $v
                }
            }
        }
    }
    elseif($Object.$PropName -is [System.Collections.Hashtable] -and $Value -is [System.Collections.Hashtable]){
        $keys = [object[]] $Value.keys
        foreach($key in $keys){
            if($Object.$PropName.containskey($key)){
                if($Object.$PropName.$key -notcontains $Value.$key){
                    if($null -ne $Object.$PropName.$key){
                        $Object.$PropName.$key = @($Object.$PropName.$key) + $Value.$key
                    }
                    else{
                        $Object.$PropName.$key = $Value.$key
                    }
                }
            }
            else{
                $Object.$PropName.$key = $Value.$key
            }
        }
    }
    else{
        $Object.$PropName = @($Object.$PropName) + $Value
    }

    if($PassThru){
        $Object
    }
}

function Search-Property {
    param(
        [parameter(Position=0)][string] $Pattern = ".",
        [parameter(ValueFromPipeline)][psobject[]] $Object,
        [switch] $SearchInPropertyNames,
        [switch] $ExcludeValues,
        [switch] $LiteralSearch,
        [string[]] $Property = "*",
        [string[]] $ExcludeProperty,
        [string] $ObjectNameProp,
        [switch] $CaseSensitive,
        [switch] $IgnoreCollections
    )
    begin{
        if($LiteralSearch -and $Pattern -ne "."){
            $Pattern = [regex]::Escape($Pattern)            
        }

        if($CaseSensitive){
            $Pattern = "(?-i)$Pattern"
        }

        $origpattern = $Pattern
    }
    process{
        foreach($o in $Object){
            if(!$LiteralSearch -and $origpattern  -match "<[^>]+>"){
                $Pattern = [regex]::Replace($origpattern, "<([^>]+)>", {[regex]::Escape($o.($args[0].value -replace "<|>"))})
            }
            $o.psobject.properties | 
                Where-Object {
                    $PropName = $_.name
                    $_.membertype -ne 'AliasProperty' -and 
                    (
                        $(if(!$ExcludeValues){$_.value -as [string] -and $_.value -match $Pattern}) -or
                        $(if($SearchInPropertyNames){$_.value -as [string] -and $_.name -match $Pattern})
                    ) -and
                    !($ExcludeProperty | Where-Object {$PropName -like $_}) -and
                    ($Property | Where-Object {$PropName -like $_}) -and
                    (!$IgnoreCollections -or $_.value -isnot [collections.ilist])
                } | Sort-Object -Property Name | Select-Object -Property @{n = "Object"; e = {if($ObjectNameProp){$o.$ObjectNameProp}else{$o.tostring()}}}, Name, Value
        }
    }
}

function Compare-ObjectProperty {
param(
    $ReferenceObject,
    $DifferenceObject,
    [switch] $IncludeEqual,
    [switch] $ExcludeDifferent,
    [string[]] $Property = "*",
    [string[]] $Exclude,
    [string] $NameProperty,
    [string] [ValidateSet('None','Empty','NonEmpty','BothEmpty')] $Hide = 'None',
    [Parameter(Dontshow = $true)][string[]] $_refs,
    [Parameter(Dontshow = $true)][string[]] $_diffs
)

    $allprops = @()
    $rp = @()    
    $dp = @()    
    $rs = 'r:'
    $ds = 'd:'

    $rID = $null
    $dID = $null

    if($null -ne $referenceobject){    
        $rp = $referenceobject.psobject.Properties |    
                Where-Object {$_.membertype -ne 'AliasProperty'} |    
                    Select-Object -ExpandProperty Name

        $allprops = @($rp)   
         
        if($NameProperty){
            $objname = $ReferenceObject.$NameProperty
        }
        else{
            $objname = $referenceobject.tostring()
        }
        $rs = "r:" + $objname

        $rID = $referenceobject.gettype().fullname + "-" + $(if($ReferenceObject.fullname){$ReferenceObject.fullname}else{$ReferenceObject.gethashcode()}) + 
                $rp
    }

    if($null -ne $differenceobject){    
        $dp = $differenceobject.psobject.Properties |
                Where-Object {$_.membertype -ne 'AliasProperty'} |
                    Select-Object -ExpandProperty Name
        
        foreach($p in $dp){    
            if($allprops -notcontains $p){
                $allprops += $p
            }
        }

        if($NameProperty){
            $objname = $DifferenceObject.$NameProperty
        }
        else{
            $objname = $DifferenceObject.tostring()
        }

        $ds = "d:" + $objname

        $dID = $differenceobject.gettype().fullname + "-" + $(if($DifferenceObject.fullname){$DifferenceObject.fullname}else{$DifferenceObject.gethashcode()}) + 
                $dp
    }

    $allprops = $allprops | Where-Object {
            $pp = $_
            ($Property | Where-Object {$pp -like $_}) -and !($Exclude | Where-Object {$pp -like $_})
        } | Sort-Object
    
    if($_refs -eq $rID -or $_diffs -eq $dID){
        return
    }

    if($ra -and $ra.gettype().fullname -in 'System.RuntimeType', 'System.Reflection.RuntimeAssembly'){
        return
    }

    $_refs += $rID
    $_diffs += $dID

    foreach($p in $allprops){        
        $ra = $referenceobject.$p
        $da = $differenceobject.$p

        if($referenceobject -is [ScriptBlock] -and $p -in 'Id', 'StartPosition'){
            continue            
        }

        if($differenceobject -is [ScriptBlock] -and $p -in 'Id', 'StartPosition'){
            continue            
        }

        $raempty = $null -eq $ra -or
                    '' -eq $ra -or
                    (($ra -is [collections.ilist] -or $ra -is [Collections.IDictionary]) -and $ra.count -eq 0) -or
                    $ra -is [System.DBNull]

        $daempty = $null -eq $da -or    
                    '' -eq $da -or    
                    (($da -is [collections.ilist] -or $da -is [Collections.IDictionary]) -and $da.count -eq 0) -or
                    $ra -is [System.DBNull]

        $rtype = if($null -eq $ra){"NULL"}else{$ra.gettype().fullname}
        $dtype = if($null -eq $da){"NULL"}else{$da.gettype().fullname}

        $equal = $null
        
        if($hide -eq 'Empty' -and ($raempty -or $daempty)){    
            continue
        }    
        elseif($hide -eq 'BothEmpty' -and $raempty -and $daempty){    
            continue    
        }    
        elseif($hide -eq 'NonEmpty' -and (!$raempty -or !$daempty)){    
            continue    
        }

        if(($raempty -and !$daempty) -or ($dp -contains $p -and $rp -notcontains $p)){    
            $equal = "=>"    
        }    
        elseif((!$raempty -and $daempty) -or ($rp -contains $p -and $dp -notcontains $p)){    
            $equal = "<="    
        }    
        elseif($rtype -ne $dtype){    
            $equal = "<>"    
        }    
        elseif($ra -is [collections.idictionary]){    
            $ra = @($ra.GetEnumerator())    
            $da = @($da.GetEnumerator())

            if(Compare-Object -ReferenceObject $ra -DifferenceObject $da -Property Key, Value){    
                $equal = "<>"    
            }    
            else{    
                $equal = "=="    
            }    
        }
        
        if(!$equal){
            if($ra.psbase.count -and $da.psbase.count -and $ra -isnot [collections.ilist] -and $ra.psobject.methods.name -contains 'GetEnumerator' -and $da.psobject.methods.name -contains 'GetEnumerator'){
                $ra = $ra.getenumerator() | Select-Object -Property *
                $da = $da.getenumerator() | Select-Object -Property *
            }

            if($ra -is [collections.ilist]){    
                if(Compare-Object -ReferenceObject $ra -DifferenceObject $da){    
                    $equal = "<>"    
                }    
                else{    
                    $equal = "=="    
                }    
            }    
        }
        
        if(!$equal){
            if($ra -and $ra -is [scriptblock] -or $ra -is [System.Management.Automation.Language.ScriptBlockAst]){
                $equal = if($ra.tostring() -eq $da.tostring()){"=="}else{"<>"}    
            }
            elseif($ra -and $da -and $ra -isnot [string] -and !$ra.gettype().IsValueType){
                if(Compare-ObjectProperty -ReferenceObject $ra -DifferenceObject $da -_refs $_refs -_diffs $_diffs){    
                    $equal = "<>"    
                }    
                else{    
                    $equal = "=="    
                }    
            }               
            else{    
                $equal = if($ra -eq $da){"=="}else{"<>"}    
            }
        }

        if((!$Excludedifferent -and $equal -ne '==') -or ($includeequal -and $equal -eq '==')){    
            [pscustomobject] @{    
                Property = $p    
                Relation = $equal    
                $rs = $ReferenceObject.$p
                $ds = $DifferenceObject.$p
            }    
        }
    }
}
#endregion

Export-ModuleMember -Variable scriptinvocation -Function '*' 
