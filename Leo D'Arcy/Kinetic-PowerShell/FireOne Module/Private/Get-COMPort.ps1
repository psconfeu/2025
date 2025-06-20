Function Get-COMPort
{
    [cmdletbinding()]
    Param
    (
        [Parameter()]
        [Switch]
        $All
    )

    $COM = [System.IO.Ports.SerialPort]::GetPortNames()

    if ($All)
    {
        Write-PSFMessage -Level Verbose -Message "Returning list of all currently avalible COM Ports"
        if ($COM.Count -lt 1)
        {
            Write-PSFMessage -Level Warning -Message "No COM Ports found"
        }
        foreach($port in $COM)
        {
            Write-PSFMessage -Level Verbose -Message "Found Port $port"
        }
        return $COM
    }
    else
    {
        if ($null -eq $COM -or $COM.Count -lt 1)
        {
            Write-PSFMessage -Level Critical -Message "Unable to locate any COM ports"
        }
    
        $DesiredCOM = Get-PSFConfigValue -FullName "$Script:ModuleName.Port.Name" -Fallback "COM1" -NotNull
        if ($COM -notcontains $DesiredCOM)
        {
            Write-PSFMessage -Level Critical -Message "Unable to locate Serial Port $DesiredCOM"
            return $null
        }
        else 
        {
            return $DesiredCOM
        }
    }
}