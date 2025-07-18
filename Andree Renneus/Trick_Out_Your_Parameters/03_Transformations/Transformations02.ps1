class ColorTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputObject) {
        if ($InputObject -is [System.Drawing.Color]) {
            return $inputObject
        }
        if ($InputObject -is [String]) {
            if ($InputObject.StartsWith('#')) {
                $hex = [System.Convert]::FromHexString($InputObject.Substring(1))
                return [System.Drawing.Color]::FromArgb($hex[0], $hex[1], $hex[2])
            }
            $Color = [System.Drawing.Color]::FromName($inputObject)
            if ($Color.ToArgb() -ne 0) {
                # [System.Drawing.Color]::FromName($null).IsEmpty returns $false
                return $Color
            }
        }
        throw "Cannot convert '$InputObject' to a System.Drawing.Color - try again"
        # return $InputObject
    }
}
function Test-Color {
    <#
        [System.Drawing.Color]'black'
    #>
    [CmdletBinding()]
    param(
        [ColorTransformation()]
        [System.Drawing.Color] $MyColor
    )
    $MyColor
}
Test-Color 'Red'
Test-Color '#FFF000'
Test-Color ([system.drawing.color]::AliceBlue)

Test-Color 'Fail'
ShowAttributes Test-Color
