#XOR all elements of the array together
Function New-CheckSum
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [Byte[]]
        $Data
    )

    $CheckSum = 0
    foreach ($item in $Data)
    {
        $CheckSum = $CheckSum -bxor $item
    }

    return $CheckSum
}