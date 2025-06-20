Function Test-FirePower
{
    [CmdletBinding()]
    Param
    (
    )

    $FirePowerStatusRequest = [byte[]]::new(11)

    $FirePowerStatusRequest[0] = 36
    $FirePowerStatusRequest[1] = 36
    $FirePowerStatusRequest[2] = 0
    $FirePowerStatusRequest[3] = 68
    $FirePowerStatusRequest[4] = 0
    $FirePowerStatusRequest[5] = 0
    $FirePowerStatusRequest[6] = 0
    $FirePowerStatusRequest[7] = 0
    $FirePowerStatusRequest[8] = 0
    $FirePowerStatusRequest[9] = 0
    $FirePowerStatusRequest[10] = 0

    $FirePowerStatusResult = Send-RawData -RAWData $FirePowerStatusRequest -IgnoreChecksum #For some reason the panel doesn't provide a valid checksum for this request

    if ($FirePowerStatusResult[4] -eq 0)
    {
        return $false;
    }
    else 
    {
        if ($FirePowerStatusResult[4] -ne 255 -or $FirePowerStatusResult[5] -ne 255)
        {
            Write-PSFMessage -Level Warning "Unknown Response from Panel: $($FirePowerStatusResult), Assuming FirePower is On!"
        }
        return $true
    }
}