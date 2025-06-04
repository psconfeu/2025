#requires -version 7.4
#requires -module CimCmdlets
#requires -module SmbShare

#the function assumes your credential has admin rights on any remote computer
Function Get-ServerDetail {
    [cmdletbinding()]
    [OutputType('PSServerDetail')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('CN')]
        [string]$Computername = $env:computername
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    } #begin

    Process {
        #create a temporary CimSession
        Try {
            Write-Verbose "Creating a temporary CimSession for $($Computername.ToUpper())"
            $cs = New-CimSession -ComputerName $Computername -ErrorAction Stop
        }
        Catch {
            Write-Warning "Failed to create a CimSession for $($Computername.ToUpper()). $($_.Exception.Message)"
        }
        If ($cs) {
            Write-Verbose "Getting operating system information for $($Computername.ToUpper())"
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs
            Write-Verbose "Getting shares for $($Computername.ToUpper())"
            #ignore errors if there are no shares
            $shares = Get-SmbShare -CimSession $Computername -Special $False -ErrorAction SilentlyContinue
            #get services
            Write-Verbose "Getting running services for $($Computername.ToUpper())"
            $svc = Get-CimInstance -ClassName Win32_Service -CimSession $cs -Filter "State = 'Running'"

            Write-Verbose "Creating a custom server object for $($Computername.ToUpper())"
            [PSCustomObject]@{
                PSTypeName       = 'PSServerDetail'
                Computername     = $os.CSName
                OperatingSystem  = $os.Caption
                InstallDate      = $os.InstallDate
                Memory           = $os.TotalVisibleMemorySize
                FreeMemory       = $os.FreePhysicalMemory
                RunningProcesses = $os.NumberOfProcesses - 2  #subtract System and Idle processes
                RunningServices  = $svc.Count
                LastBoot         = $os.LastBootUpTime
                Shares           = $shares
            }
            Write-Verbose "Removing temporary CimSession for $($Computername.ToUpper())"
            Remove-CimSession -CimSession $cs
        } #If CimSession
    } #process

    End {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    } #end

} #close function

#Extending type data
$splat = @{
    TypeName   = 'PSServerDetail'
    MemberType = 'ScriptProperty'
    MemberName = $Null
    Value      = $null
    Force      = $True
}

$splat.MemberName = 'Uptime'
$splat.Value = { New-TimeSpan -Start $this.LastBoot -End (Get-Date) }
Update-TypeData @splat

$splat.MemberType = 'NoteProperty'
$splat.MemberName = 'AuditDate'
$splat.Value = (Get-Date)
Update-TypeData @splat

$splat.MemberType = 'AliasProperty'
$splat.MemberName = 'OS'
$splat.Value = 'OperatingSystem'
Update-TypeData @splat

Update-FormatData $PSScriptRoot\PSServerDetail.format.ps1xml
