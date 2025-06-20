Function Test-FireReady
{
    [CmdletBinding()]
    Param
    (
    )

    $FireReadyStatusRequest = [byte[]]::new(11)

    $FireReadyStatusRequest[0] = 36
    $FireReadyStatusRequest[1] = 36
    $FireReadyStatusRequest[2] = 0
    $FireReadyStatusRequest[3] = 68
    $FireReadyStatusRequest[4] = 1
    $FireReadyStatusRequest[5] = 255
    $FireReadyStatusRequest[6] = 255
    $FireReadyStatusRequest[7] = 0
    $FireReadyStatusRequest[8] = 0
    $FireReadyStatusRequest[9] = 0
    $FireReadyStatusRequest[10] = 0

    $FireReadyStatusResult = Send-RawData -RAWData $FireReadyStatusRequest -IgnoreChecksum #For some reason the panel doesn't provide a valid checksum for this request

    if ($FireReadyStatusResult[4] -eq 0)
    {
        return $false;
    }
    else 
    {
        if ($FireReadyStatusResult[4] -ne 255 -or $FireReadyStatusResult[5] -ne 255)
        {
            Write-PSFMessage -Level Warning "Unknown Response from Panel: $($FirePowerStatusResult), Assuming FirePower is On!"
        }
        return $true
    }
}