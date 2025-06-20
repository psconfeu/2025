Function Get-Module
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateRange(1,99)]
        [Int]
        $Module
    )

    Write-PSFMessage -Level Verbose -Message "Requesting Module Version Information"

    $Request = [byte[]]::new(11)
    $Request[0] = 35
    $Request[1] = 35
    $Request[2] = $Module
    $Request[3] = 86
    $Request[4] = 0
    $Request[5] = 0
    $Request[6] = 0
    $Request[7] = 0
    $Request[8] = 0
    $Request[9] = 0
    $Request[10] = 0

    $ModuleData = Send-RawData -RAWData $Request

    if ($ModuleData[0] -eq 0)
    {
        Write-PSFMessage -Level Critical -Message "No response from Panel"
        return
    }

    Write-PSFMessage -Level Verbose -Message "Requesting Module Alert Information"

    $AlertRequest = [byte[]]::new(11)
    $AlertRequest[0] = 35
    $AlertRequest[1] = 35
    $AlertRequest[2] = $Module
    $AlertRequest[3] = 73
    $AlertRequest[4] = 82
    $AlertRequest[5] = 1
    $AlertRequest[6] = 0
    $AlertRequest[7] = 0
    $AlertRequest[8] = 0
    $AlertRequest[9] = 0
    $AlertRequest[10] = 0

    $AlertData = Send-RawData -RAWData $AlertRequest

    switch ($AlertData[6]) {
        0 {
            $AlertType = "No Alert"
        }
        1 {
            if ($AlertData[7] -eq 0)
            {
                $AlertType = "Continuous"
            }
            else 
            {
                $AlertType = "Timed"    
            }
        }

        Default {
            Write-Warning "Unknown Alert Type $($AlertData[6])"
            $AlertType = "Unknown"
        }
    }

    $AlertLength = $AlertData[7]

    Write-PSFMessage -Level Verbose -Message "Requesting Module Radio Channel Information"

    $ChannelRequest = [byte[]]::new(11)
    $ChannelRequest[0] = 35
    $ChannelRequest[1] = 35
    $ChannelRequest[2] = $Module
    $ChannelRequest[3] = 73
    $ChannelRequest[4] = 82
    $ChannelRequest[5] = 5
    $ChannelRequest[6] = 0
    $ChannelRequest[7] = 0
    $ChannelRequest[8] = 0
    $ChannelRequest[9] = 0
    $ChannelRequest[10] = 0

    $ChannelData = Send-RawData -RAWData $ChannelRequest

    Write-PSFMessage -Level Verbose -Message "Requesting Module Security Code Information"

    $SecurityCodeRequest = [byte[]]::new(11)
    $SecurityCodeRequest[0] = 35
    $SecurityCodeRequest[1] = 35
    $SecurityCodeRequest[2] = $Module
    $SecurityCodeRequest[3] = 73 #49
    $SecurityCodeRequest[4] = 82 #52
    $SecurityCodeRequest[5] = 7 #07
    $SecurityCodeRequest[6] = 0
    $SecurityCodeRequest[7] = 0
    $SecurityCodeRequest[8] = 0
    $SecurityCodeRequest[9] = 0
    $SecurityCodeRequest[10] = 0

    $SecurityCodeData = Send-RawData -RAWData $SecurityCodeRequest

    Write-PSFMessage -Level Verbose -Message "Requesting Module Firing Duration Information"

    $FireDurationRequest = [byte[]]::new(11)
    $FireDurationRequest[0] = 35
    $FireDurationRequest[1] = 35
    $FireDurationRequest[2] = $Module
    $FireDurationRequest[3] = 73 #49
    $FireDurationRequest[4] = 82 #52
    $FireDurationRequest[5] = 8 #08
    $FireDurationRequest[6] = 0
    $FireDurationRequest[7] = 0
    $FireDurationRequest[8] = 0
    $FireDurationRequest[9] = 0
    $FireDurationRequest[10] = 0

    $FireDurationData = Send-RawData -RAWData $FireDurationRequest

    return New-Object -TypeName PSObject -Property @{
        Module = $Module
        AlertType = $AlertType
        AlertLength = $AlertLength
        RadioChannel = $ChannelData[6]
        SecurityCode = "{0:X2}-{1:X2}-{2:X2}-{3:X2}" -f $SecurityCodeData[6], $SecurityCodeData[7], $SecurityCodeData[8], $SecurityCodeData[10]
        FiringDuration = "$($FireDurationData[6])ms"
        Version = [System.Text.Encoding]::ASCII.GetString($ModuleData[3..10])
    }
}