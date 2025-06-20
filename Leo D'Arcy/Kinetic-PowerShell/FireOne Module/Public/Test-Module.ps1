
#TODO: create parameterset for testing a specific Cue
Function Test-Module
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateRange(1,99)]
        [Int]
        $Module,
        [Parameter()]
        [ValidateRange(1,32)]
        [Int]
        $Cue
    )

    if (Test-FirePower)
    {
        throw "Unable to test while Firepower is enabled"
    }

    Write-PSFMessage -Level Verbose -Message "Requesting Module Cue Information"

    $Request = [byte[]]::new(11)
    $Request[0] = 35
    $Request[1] = 35
    $Request[2] = $Module
    $Request[3] = 84
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

    $ModuleInfo = @()
    $ModuleInfo += for ($i = 0; $i -lt 32; $i++)
    {
        $ByteOffset = [math]::floor($i/8)
        $bit = $i % 8

        $ByteString = [convert]::ToString($ModuleData[8-$ByteOffset],2) #Ignore the final 2 bytes and count back from right to left
        $ByteString = $ByteString.PadLeft(8,'0')
        Write-Debug "Byte String is $ByteString"
        $BitValue = [int]::Parse($ByteString[7-$bit])

        Write-Debug "Looking at $bit in $ByteOffset"

        if ($BitValue -eq 1)
        {
            $Status = $true
        }
        else
        {
            $Status = $false
        }

        New-Object -TypeName PSObject -Property @{
            Module = $Module
            Cue = $i+1
            Status = $Status
        }
    }

    if (0 -ne $Cue) # int defaults to 0 when not specified
    {
        $ModuleInfo = $ModuleInfo | Where-Object {$_.Cue -eq $Cue}
    }

    return $ModuleInfo
}