Function Disconnect-Panel
{
    [cmdletbinding()]
    Param
    (
    )

    if ($null -ne $Script:Port)
    {
        Write-PSFMessage -Level Verbose -Message "Closing Port $($Script:Port.PortName)"
        $Script:Port.Close()
        $Script:Port = $null # remove the exisintg instance as it is now closed, connect will then create a new instance as required
        Write-PSFMessage -Level Verbose -Message "Port Closed"
    }
    else 
    {
        Write-PSFMessage -Level Warning -Message "No Port Open"
    }
}