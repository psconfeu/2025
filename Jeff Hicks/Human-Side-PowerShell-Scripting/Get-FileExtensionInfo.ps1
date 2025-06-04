#requires -version 7.5

#Get-FileExtensionInfo.ps1

using namespace System.Collections.generic

Function Get-FileExtensionInfo {
    [cmdletbinding()]
    [alias('gfei')]
    [OutputType('FileExtensionInfo')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the root directory path to search'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ },ErrorMessage = 'Cannot find or verify the path {0}.')]
        [string]$Path = '.',

        [Parameter(HelpMessage = 'Recurse through all folders.')]
        [switch]$Recurse,

        [Parameter(HelpMessage = 'Include files in hidden folders')]
        [switch]$Hidden,

        [Parameter(HelpMessage = 'Add the corresponding collection of files')]
        [Switch]$IncludeFiles
    )

    Begin {
        Write-Information -MessageData $MyInvocation
        #set a version for this stand-alone function
        $ver = '1.3.0'
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand) v$ver"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using PowerShell Host $($Host.Name)"
        #capture the current date and time for the audit date
        $report = Get-Date

        $enumOpt = [System.IO.EnumerationOptions]::new()
        if ($Recurse) {
            Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Getting files recursively"
            $enumOpt.RecurseSubdirectories = $Recurse
        }
        if ($Hidden) {
            Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Including hidden files"
            $enumOpt.AttributesToSkip = 2
        }
        Write-Information -MessageData $enumOpt
        #initialize a list to hold the results
        $list = [list[object]]::new()

        #determine the platform. This will return a value like Linux, MacOS, or Windows
        $platform = (Get-Variable IsWindows, IsMacOS, IsLinux | where { $_.value }).Name -replace 'is', ''
    } #begin

    Process {
        Write-Information -MessageData $PSBoundParameters
        #convert the path to a file system path
        $cPath = Convert-Path -Path $Path

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $cPath"
        $dir = Get-Item -Path $cPath
        #using the .NET GetFiles() method for performance.
        #the enumOption is not available in Windows PowerShell
        $files = $dir.GetFiles('*', $enumOpt)

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting the total sum of all files"
        $TotalSum = $files | Measure-Object -Property length -Sum
        Write-Information -MessageData $TotalSum
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Found $($files.count) files"
        $group = $files | Group-Object -Property extension

        #Group and measure
        foreach ($item in $group) {
            Write-Information -MessageData $item.Group
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Measuring $($item.count) $($item.name) files"
            $measure = $item.Group | Measure-Object -Property length -Minimum -Maximum -Average -Sum

            #create a custom object
            $out = [PSCustomObject]@{
                PSTypeName       = 'FileExtensionInfo'
                Path             = $cPath
                Extension        = $item.Name.Replace('.', '')
                Count            = $item.Count
                PercentTotal     = [math]::Round(($item.Count / $files.Count), 2)  #<-- cast as double for sorting
                TotalSize        = $measure.Sum  #<-- don't format numbers here to KB or MB
                TotalSizePercent = [math]::Round(($measure.Sum / $TotalSum.Sum), 4)
                SmallestSize     = $measure.Minimum
                LargestSize      = $measure.Maximum
                AverageSize      = $measure.Average
                Computername     = [System.Environment]::MachineName  #<-- extra information
                Platform         = $platform #<-- extra information
                ReportDate       = $report #<-- extra information
                Files            = $IncludeFiles ? $item.group : $null  #<-- extra information
                IsLargest        = $False  #<-- extra information
            }
            $list.Add($out)
        }
    } #process

    End {
        #mark the extension with the largest total size
        ($list | Sort-Object -Property TotalSize, Count)[-1].IsLargest = $True
        #write the results to the pipeline
        $list
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end
} #close Get-FileExtensionInfo

#Add an alias property
Update-TypeData -TypeName FileExtensionInfo -MemberType AliasProperty -MemberName Total -Value TotalSize -Force

#Add script properties
Update-TypeData -TypeName FileExtensionInfo -MemberType ScriptProperty -MemberName TotalMB -value { $this.TotalSize/1mb} -Force
Update-TypeData -TypeName FileExtensionInfo -MemberType ScriptProperty -MemberName TotalKB -value { $this.TotalSize/1kb} -Force

#load the custom format file
Update-FormatData $PSScriptRoot\FileExtensionInfo.format.ps1xml
