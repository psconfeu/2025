Function Get-DriveInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]$DriveLetter = 'C:'
    )

    $data = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter'"
    Write-Host "Processing $($data.Name)" -ForegroundColor Green
    # code continues ...
}

Function Get-DriveInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [ValidatePattern('^[A-Za-z]', ErrorMessage = '{0} is an invalid drive letter.')]
        [string]$Drive = 'C'
    )

    $DriveLetter = "$($Drive):"
    $data = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter'"
    if ($data) {
        Write-Host "Processing $($data.Name)" -ForegroundColor Green
        # code continues ...
    }
    else {
        Write-Warning "Drive $DriveLetter not found."
    }
}

#or give them tab completion
Function Get-DriveInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        #add an argument completer for the drive names from win32_LogicalDisk
        [ArgumentCompleter({
                [OutputType([System.Management.Automation.CompletionResult])]
                param(
                    [string] $CommandName,
                    [string] $ParameterName,
                    [string] $WordToComplete,
                    [System.Management.Automation.Language.CommandAst] $CommandAst,
                    [System.Collections.IDictionary] $FakeBoundParameters
                )

                $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

                $DriveLetters = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID
                foreach ($DriveLetter in $DriveLetters) {
                    if ($DriveLetter -like "$WordToComplete*") {
                        $CompletionResults.Add((New-Object System.Management.Automation.CompletionResult($DriveLetter, $DriveLetter, 'ParameterValue', $DriveLetter)))
                    }
                }

                return $CompletionResults
            })]
        [ValidatePattern('^[A-Za-z]:', ErrorMessage = '{0} is an invalid drive letter.')]
        [string]$Drive = 'C:'
    )

    $data = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$Drive'"
    if ($data) {
        Write-Host "Processing $($data.Name)" -ForegroundColor Green
        # code continues ...
    }
    else {
        Write-Warning "Drive $DriveLetter not found."
    }
}

Function Save-Data {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = 'Specify the path to save.')]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'The path {0} does not exist.')]
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.',
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,
        [switch]$Force
    )

    $cPath = Convert-Path -Path $path
    Write-Host "Saving data from $cPath" -ForegroundColor cyan
    #code that needs a normal file system path
}

Function Backup-ADComputer {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Computername
    )
    Begin {}
    Process {
        Write-Host "Backing up $Computername" -ForegroundColor cyan
        #code
    }
    End {}
}

Function Backup-ADComputer {
    [cmdletbinding()]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Alias('ComputerName')]
        [string]$Name
    )
    Begin {}
    Process {
        Write-Host "Backing up $Name" -ForegroundColor cyan
        #code
    }
    End {}
}

#using parameter sets
Function Backup-ADComputer {
    [cmdletbinding(DefaultParameterSetName = 'ByName')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'ByName'
        )]
        [alias('Name', 'CN')]
        [ValidateNotNullOrEmpty()]
        [string]$Computername = $env:COMPUTERNAME,
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'ByADComputer'
        )]
        [ValidateNotNullOrEmpty()]
        [Microsoft.ActiveDirectory.Management.ADComputer]$ADComputer
    )
    Begin {}
    Process {
        Write-Verbose "Detected parameter set $($PSCmdlet.ParameterSetName)"
        if ($PSCmdlet.ParameterSetName -eq 'byADComputer') {
            $Computername = $ADComputer.Name
        }
        Write-Host "Backing up $Computername" -ForegroundColor cyan
        #code
    }
    End {}
}

#write rich objects - use formatting to set defaults

Function Resolve-WhoIs {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline
        )]
        [string]$IPAddress
    )
    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        $baseURL = 'http://whois.arin.net/rest'
    }
    Process {
        Write-Verbose "Resolving IP $IPAddress"
        $url = "$baseUrl/ip/$IPAddress"
        $r = Invoke-RestMethod $url
        if ($r.net) {
            [PSCustomObject]@{
                IP                     = $IPAddress
                Name                   = $r.net.name
                RegisteredOrganization = $r.net.orgRef.name
            }
        }
    }
    End {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}

Resolve-WhoIs 8.8.8.8

Function Resolve-WhoIs {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline
        )]
        [string]$IPAddress
    )
    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        $baseURL = 'http://whois.arin.net/rest'
    }
    Process {
        Write-Verbose "Resolving IP $IPAddress"

        $url = "$baseUrl/ip/$IPAddress"
        $r = Invoke-RestMethod $url
        if ($r.net) {
            $NetBlocks = $r.net.netBlocks.netBlock |
            ForEach-Object { "$($_.StartAddress)/$($_.cidrLength)" }
            $City = (Invoke-RestMethod $r.net.orgRef.'#text').org.city

            [PSCustomObject]@{
                PSTypeName             = 'WhoIsResult'
                IP                     = $IPAddress
                Name                   = $r.net.name
                RegisteredOrganization = $r.net.orgRef.Name
                OrganizationHandle     = $r.net.orgRef.Handle
                City                   = $City
                StartAddress           = $r.net.startAddress
                EndAddress             = $r.net.endAddress
                NetBlocks              = $NetBlocks
                Updated                = $r.net.updateDate -as [DateTime]
            }
        }
    }
    End {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}

Function Get-BasicFileExtensionInfo {
    [cmdletbinding()]
    Param(
        [string]$Path = ".",
        [switch]$Recurse,
        [switch]$Hidden
    )

    Begin {
        $enumOpt = [System.IO.EnumerationOptions]::new()
        if ($Recurse) {
            $enumOpt.RecurseSubdirectories = $Recurse
        }
        if ($Hidden) {
            $enumOpt.AttributesToSkip = 2
        }
    } #begin

    Process {
        $dir = Get-Item -Path $Path
        $dir.GetFiles('*', $enumOpt) |
        Group-Object -Property extension -PipelineVariable pv |
        Foreach-Object {
            $_.Group | Measure-Object -Property length -Minimum -Maximum -Average -Sum
        } | Select-Object @{Name="Path";Expression={$Path}},
        @{Name="Extension";Expression={$pv.Name.Replace('.', '')}},
        Count,
        @{Name="TotalSize";Expression={$_.Sum}},
        @{Name="SmallestSize";Expression={$_.Minimum}},
        @{Name="LargestSize";Expression={$_.Maximum}},
        @{Name="AverageSize";Expression={$_.Average}}

    } #process

}
Function Get-FileGroup {
    [cmdletbinding()]
    [OutputType('psFileGroup')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, HelpMessage = 'Specify the folder to search')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path = '.',
        [switch]$Recurse,
        [Parameter(Mandatory)]
        [ValidateSet('graphics', 'powershell', 'office', 'data')]
        [string]$Category
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Getting $Category files"
        #remove category from PSBoundParameters
        [void]$PSBoundParameters.Remove('Category')

        #add File to PSBoundParameters
        $PSBoundParameters.add('File', $True)

        Switch ($Category) {
            'graphics' {
                $filter = '\.(bmp)|(jpg)|(jpeg)|(png)|(gif)$'
            }
            'powershell' {
                $filter = '\.ps(d)?1(xml)?$'
            }
            'office' {
                $filter = '\.(doc(x?))|(ppt(x)?)|(xls(x)?)$'
            }
            'data' {
                $filter = '\.(json)|(db)|(xml)|(csv)$'
            }
        } #close Switch
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $Path"

        $data = Get-ChildItem @PSBoundParameters |
        Where-Object { $_.extension -Match $filter } |
        Measure-Object -Property Length -Sum

        [PSCustomObject]@{
            PSTypeName   = 'psFileGroup'
            Path         = Convert-Path -Path $Path
            Count        = $data.Count
            Sum          = $data.Sum
            Category     = $Category
            ComputerName = [Environment]::MachineName
            Platform     = (Get-Variable IsWindows,IsMacOS,IsLinux | where {$_.value}).Name -replace "is",""
            ReportDate   = (Get-Date)
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FileGroup