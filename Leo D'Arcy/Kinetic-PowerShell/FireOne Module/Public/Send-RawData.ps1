Function Send-RawData
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [byte[]]
        $RAWData,
        [Parameter()]
        [ValidateRange(1,3600000)]
        [int]
        $Timeout=5000, #Default commands to a 5 second timeout
        [Parameter()]
        [Switch]
        $IgnoreChecksum,
        [Parameter()]
        [Switch]
        $NoResponse
    )

    try 
    {
        if ($null -eq $Script:Port)
        {
            Write-PSFMessage -Level Verbose -Message "Opening Port $PortName"
            $PortName = Get-COMPort
            if ($null -eq $PortName)
            {
                throw "No COM Port identified, please plug in the FireOne Module or set the desired COM port with the command 'Set-PSFConfig -Module FireOne -Name FireOne.Port.Name -Value COM1'"
            }
            $PortSpeed = Get-PSFConfigValue -FullName "$Script:ModuleName.Port.Speed" -Fallback "19200" -NotNull
            Write-PSFMessage -Level Verbose -Message "$PortName will be opened at $PortSpeed baud"
            $Script:Port = New-Object -TypeName System.IO.Ports.SerialPort -ArgumentList $PortName, $PortSpeed, None, 8, One #8N1 control
            $Script:Port.DtrEnable = $true
            $Script:Port.ReadBufferSize = 4096
            $Script:Port.WriteBufferSize = 19200
            $Script:Port.Open()
            Write-PSFMessage -Level Verbose -Message "Port Open"
        }
        else 
        {
            Write-PSFMessage -Level Verbose "Using already open Port $Script:Port"    
        }
    }
    catch
    {
        if ($null -eq $($Script:Port.PortName))
        {
            Write-PSFMessage -Level Critical "Unable to Open COM port: $($_.Exception.Message)"    
        }
        else
        {
            Write-PSFMessage -Level Critical "Unable to Open COM port $($Script:Port.PortName): $($_.Exception.Message)"
        }
        
        #Stop execution of any higher level functions as they assume that data will be returned from the module
        throw "Unable to access FireOne Panel"
    }


    Write-PSFMessage -Level Verbose -Message "$($Script:Port.PortName) will be used"
    
    [byte[]]$DataToSend = $RAWData
    $DataToSend += New-CheckSum -Data $RAWData

    try 
    {
        #Results are the same size as the request
        $Result = [byte[]]::new($DataToSend.Count)

        Write-PSFMessage -Level Verbose -Message "Sending data $DataToSend"
        $Script:Port.Write($DataToSend, 0, $DataToSend.Count)
        if (-NOT $NoResponse)
        {
            Write-PSFMessage -Level Verbose -Message "Data Sent, waiting for response"
            $ReadCount = 0
            $stopwatch = [system.diagnostics.stopwatch]::StartNew()
            do
            {
                if ($port.BytesToRead -gt 0)
                {
                    $CurrentBytesToRead = $Script:Port.BytesToRead
                    $newBytes = [byte[]]::new($CurrentBytesToRead)
                    $ActualByteCount = $Script:Port.Read($newBytes, 0, $CurrentBytesToRead)
                    for ($i = 0; $i -lt $ActualByteCount; $i++)
                    {
                        $Result[$ReadCount + $i] = $newBytes[$i]   
                    }
                    $ReadCount += $ActualByteCount
                }
            } while ($ReadCount -lt $Result.Count -and $stopwatch.Elapsed.TotalMilliseconds -lt $Timeout)
            if ($ReadCount -gt 0)
            {
                Write-PSFMessage -Level Verbose -Message "Data Returned: $Result"
            }
            else
            {
                Write-PSFMessage -Level Verbose -Message "No Response"
            }
        }
        else 
        {
            $Result = $null   
        }
    }
    catch 
    {
        Write-PSFMessage -Level Critical -Message "Unable to Send Data $($_.Exception.Message)"
    }

    if (-NOT $IgnoreChecksum -and -NOT $NoResponse)
    {
        Confirm-CheckSum -Data $Result | Out-Null
    }

    return $Result
}