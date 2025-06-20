Function Connect-Panel
{
    [CmdletBinding()]
    Param
    (
    )

    $Request = [byte[]]::new(11)

    #Request?
    $Request[0] = 36
    $Request[1] = 36
    #Unknown Bytes
    $Request[2] = 0
    #Space for requested Hardware Model?
    $Request[3] = 67
    $Request[4] = 0
    $Request[5] = 0
    $Request[6] = 0
    $Request[7] = 0
    $Request[8] = 0
    $Request[9] = 0
    $Request[10] = 0

    $InitialResponse = Send-RawData -RAWData $Request

    if ($InitialResponse[0] -eq 0)
    {
        Write-PSFMessage -Level Critical -Message "No response from Panel"
        return
    }

    $VersionRequest = [byte[]]::new(11)

    $VersionRequest[0] = 36
    $VersionRequest[1] = 36
    $VersionRequest[2] = 0
    #Space for requested Fireware Version Number
    $VersionRequest[3] = 86 #V
    $VersionRequest[4] = 0
    $VersionRequest[5] = 0
    $VersionRequest[6] = 0
    $VersionRequest[7] = 0
    $VersionRequest[8] = 0
    $VersionRequest[9] = 0
    $VersionRequest[10] = 0

    $VersionResult = Send-RawData -RAWData $VersionRequest

    switch ($InitialResponse[4])
    {
        78 {$PanelModel = "XL2+"}
        Default {$PanelModel = "Unknown"}
    }

    return New-Object -TypeName PSObject -Property @{
        Model = $PanelModel
        Version = [System.Text.Encoding]::ASCII.GetString($VersionResult[3..10])
    }
}