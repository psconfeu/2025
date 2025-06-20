Function Confirm-CheckSum
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [Byte[]]
        $Data
    )

    #Create a new byte array 1 byte smaller than the data array
    $MessageData = [byte[]]::new($data.Count-1)

    #Copy everything except for the last byte into the new byte array
    $MessageData = $Data[0..($Data.Count-2)]

    #generate the checksum of the data (excluding the current checksum)
    $ComputedChecksum = New-CheckSum -Data $MessageData
    
    #Check if the current checksum matches the newly generated checksum
    if ($ComputedChecksum -eq $Data[$Data.Count-1])
    {
        Write-Debug "Data transmitted successfully"
        return $true
    }
    else 
    {
        Write-Warning "Checksum did not match data"
        return $false
    }
}