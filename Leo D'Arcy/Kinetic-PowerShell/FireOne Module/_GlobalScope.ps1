$Script:ModuleName = "FireOne"
$Script:Port = $null
Function Add-ConfigurationParameters
{
    [CmdletBinding()]
    Param()

    Write-PSFMessage -Level Verbose -Message "Loading Configuration Settings"

    Set-PSFConfig -Module $Script:ModuleName -Name "Port.Name" -Value "COM1" -Validation string -Initialize -Description "Name of the serial port to use when connecting to the FireOne control system"
    Set-PSFConfig -Module $Script:ModuleName -Name "Port.Speed" -Value 19200 -Validation integer -Initialize -Description "The connection speed of the serial port used when connecting to the FireOne control system"
}

Function Import-FireOneModule
{
    [CmdletBinding()]
    Param()
    Add-ConfigurationParameters
}

Write-PSFMessage -Level Verbose -Message "Loading Module $Script:ModuleName"
Import-FireOneModule