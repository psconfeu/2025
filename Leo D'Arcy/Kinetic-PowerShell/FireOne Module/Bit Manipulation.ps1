$cues = 1..32 #Loop from 1 - 32

foreach ($cue in $cues)
{
    #Identify the Bit flag to set
    $bit = $Cue % 8
    if ($bit -eq 0) { $bit = 8 } #value 8 should flip bit 8 not bit 0

    #Identify the byte to set
    $CueOffset = $cue - $bit #Make Divisable by 8
    $ByteOffset = ($CueOffset / 8) #Locate the correct Byte to modify
    [int]$Byte = 4 - $ByteOffset

    #Calculate the Value of the Byte
    $Value = 1 -shl ($bit - 1)

    #Set the Byte
    $Bytes = [byte[]]::new(4)
    $Bytes[$byte-1] = $Value

    #Visualise the Output
    $output = foreach ($OutputByte in $Bytes)
    {
        [Convert]::ToString($OutputByte, 2).PadLeft(8, '0')
    }
    Write-Output "[4Bytes]$output"
    Write-Output "Cue: $cue - Byte: $Byte - Bit: $bit - Value: $Value"
}

<# OUTPUT
[4Bytes]00000000 00000000 00000000 00000001
Cue: 1 - Byte: 4 - Bit: 1 - Value: 1
[4Bytes]00000000 00000000 00000000 00000010
Cue: 2 - Byte: 4 - Bit: 2 - Value: 2
[4Bytes]00000000 00000000 00000000 00000100
Cue: 3 - Byte: 4 - Bit: 3 - Value: 4
[4Bytes]00000000 00000000 00000000 00001000
Cue: 4 - Byte: 4 - Bit: 4 - Value: 8
[4Bytes]00000000 00000000 00000000 00010000
Cue: 5 - Byte: 4 - Bit: 5 - Value: 16
[4Bytes]00000000 00000000 00000000 00100000
Cue: 6 - Byte: 4 - Bit: 6 - Value: 32
[4Bytes]00000000 00000000 00000000 01000000
Cue: 7 - Byte: 4 - Bit: 7 - Value: 64
[4Bytes]00000000 00000000 00000000 10000000
Cue: 8 - Byte: 4 - Bit: 8 - Value: 128
[4Bytes]00000000 00000000 00000001 00000000
Cue: 9 - Byte: 3 - Bit: 1 - Value: 1
[4Bytes]00000000 00000000 00000010 00000000
Cue: 10 - Byte: 3 - Bit: 2 - Value: 2
[4Bytes]00000000 00000000 00000100 00000000
Cue: 11 - Byte: 3 - Bit: 3 - Value: 4
[4Bytes]00000000 00000000 00001000 00000000
Cue: 12 - Byte: 3 - Bit: 4 - Value: 8
[4Bytes]00000000 00000000 00010000 00000000
Cue: 13 - Byte: 3 - Bit: 5 - Value: 16
[4Bytes]00000000 00000000 00100000 00000000
Cue: 14 - Byte: 3 - Bit: 6 - Value: 32
[4Bytes]00000000 00000000 01000000 00000000
Cue: 15 - Byte: 3 - Bit: 7 - Value: 64
[4Bytes]00000000 00000000 10000000 00000000
Cue: 16 - Byte: 3 - Bit: 8 - Value: 128
[4Bytes]00000000 00000001 00000000 00000000
Cue: 17 - Byte: 2 - Bit: 1 - Value: 1
[4Bytes]00000000 00000010 00000000 00000000
Cue: 18 - Byte: 2 - Bit: 2 - Value: 2
[4Bytes]00000000 00000100 00000000 00000000
Cue: 19 - Byte: 2 - Bit: 3 - Value: 4
[4Bytes]00000000 00001000 00000000 00000000
Cue: 20 - Byte: 2 - Bit: 4 - Value: 8
[4Bytes]00000000 00010000 00000000 00000000
Cue: 21 - Byte: 2 - Bit: 5 - Value: 16
[4Bytes]00000000 00100000 00000000 00000000
Cue: 22 - Byte: 2 - Bit: 6 - Value: 32
[4Bytes]00000000 01000000 00000000 00000000
Cue: 23 - Byte: 2 - Bit: 7 - Value: 64
[4Bytes]00000000 10000000 00000000 00000000
Cue: 24 - Byte: 2 - Bit: 8 - Value: 128
[4Bytes]00000001 00000000 00000000 00000000
Cue: 25 - Byte: 1 - Bit: 1 - Value: 1
[4Bytes]00000010 00000000 00000000 00000000
Cue: 26 - Byte: 1 - Bit: 2 - Value: 2
[4Bytes]00000100 00000000 00000000 00000000
Cue: 27 - Byte: 1 - Bit: 3 - Value: 4
[4Bytes]00001000 00000000 00000000 00000000
Cue: 28 - Byte: 1 - Bit: 4 - Value: 8
[4Bytes]00010000 00000000 00000000 00000000
Cue: 29 - Byte: 1 - Bit: 5 - Value: 16
[4Bytes]00100000 00000000 00000000 00000000
Cue: 30 - Byte: 1 - Bit: 6 - Value: 32
[4Bytes]01000000 00000000 00000000 00000000
Cue: 31 - Byte: 1 - Bit: 7 - Value: 64
[4Bytes]10000000 00000000 00000000 00000000
Cue: 32 - Byte: 1 - Bit: 8 - Value: 128
#>