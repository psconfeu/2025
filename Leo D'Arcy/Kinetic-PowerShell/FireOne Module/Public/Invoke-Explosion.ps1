Function Invoke-Explosion
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateRange(1, 99)]
        [Int]
        $Module,
        [Parameter(Mandatory)]
        [ValidateRange(1, 32)]
        [Int]
        $Cue
    )

    $bit = $Cue % 8
    if ($bit -eq 0)
    {
        #divisable by 8 needs to modify bit 8 rather than 0
        $bit = 8 
    }

    $CueOffset = $cue - $bit #Make Divisable by 8
    $ByteOffset = ($CueOffset / 8) #Locate the correct Byte to modify

    $FirePowerInvokeRequest = [byte[]]::new(11)

    $FirePowerInvokeRequest[0] = 35
    $FirePowerInvokeRequest[1] = 35
    $FirePowerInvokeRequest[2] = $Module
    $FirePowerInvokeRequest[3] = 70
    $FirePowerInvokeRequest[4] = 0
    $FirePowerInvokeRequest[5] = 0 #Cue Flags [25-32]
    $FirePowerInvokeRequest[6] = 0 #Cue Flags [17-24]
    $FirePowerInvokeRequest[7] = 0 #Cue Flags [9-16]
    $FirePowerInvokeRequest[8] = 0 #Cue Flags [1-8]
    $FirePowerInvokeRequest[9] = 70
    $FirePowerInvokeRequest[10] = 0

    $FirePowerInvokeRequest[8 - $ByteOffset] = 1 -shl ($bit - 1)

    if (Test-FireReady)
    {
        Send-RawData -RAWData $FirePowerInvokeRequest -NoResponse

        $ExecuteFireRequest = [byte[]]::new(11)

        $ExecuteFireRequest[0] = 36
        $ExecuteFireRequest[1] = 36
        $ExecuteFireRequest[2] = 0
        $ExecuteFireRequest[3] = 33
        $ExecuteFireRequest[4] = 0
        $ExecuteFireRequest[5] = 0
        $ExecuteFireRequest[6] = 0
        $ExecuteFireRequest[7] = 0
        $ExecuteFireRequest[8] = 0
        $ExecuteFireRequest[9] = 0
        $ExecuteFireRequest[10] = 0

        Send-RawData -RAWData $ExecuteFireRequest -NoResponse
    }
    else 
    {
        Write-PSFMessage "Panel not ready to fire!" -Level Warning    
    }
}