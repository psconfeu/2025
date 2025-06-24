using namespace System.Collections.Generic
using namespace System.Management.Automation

class ColorTransformAttribute : ArgumentTransformationAttribute {
    [object] Transform(
        [EngineIntrinsics] $engineIntrinsics,
        [object] $inputObject
    ) {
        if ($InputObject -is [Drawing.Color]) {
            Write-Host ('InputObject is already a Color: {0}' -f $inputObject)
            return $inputObject
        }
        if ($InputObject -is [String]) {
            if ($InputObject.StartsWith('#')) {
                Write-Host ('InputObject is a hex color code: {0}' -f $inputObject)
                $hex = [Convert]::FromHexString($InputObject.Substring(1))
                return [Drawing.Color]::FromArgb($hex[0], $hex[1], $hex[2])
            }
            $Color = [Drawing.Color]::FromName($inputObject)
            if ($Color.ToArgb() -ne 0) {
                Write-Host ('InputObject is a valid color name: {0}' -f $inputObject)
                # FromName doesn't validate and .IsEmpty returns false even on $null
                return $Color
            }
        }
        throw 'Invalid color value: {0}. Expected a valid color name or hex code.' -f $inputObject
        # return $inputObject
    }
}



class ColorCompleter : ArgumentCompleterAttribute, IArgumentCompleter, IArgumentCompleterFactory {
    static [string[]] $Colors
    static [string] $Highlight = "`e[38;2;{0};{1};{2}m{3}`e[0m"
    static [string] $Description = '{0} R: {1}, G: {2}, B: {3}'
    static ColorCompleter() {
        [ColorCompleter]::Colors = [Drawing.Color].GetProperties('public,static').Name
    }
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [Language.CommandAst] $commandAst,
        [Collections.IDictionary] $fakeBoundParameters
    ) {
        $Results = foreach ($Name in [ColorCompleter]::Colors) {
            if ($Name -like "*$wordToComplete*") {
                $color = [Drawing.Color]::FromName($Name)
                [CompletionResult]::new(
                <# completionText: #> $Name,
                <# listItemText:   #> ([ColorCompleter]::Highlight -f $color.R, $color.G, $color.B, $Name),
                <# resultType:     #> [CompletionResultType]::ParameterValue,
                <# toolTip:        #> ([ColorCompleter]::Description -f $Name, $color.R, $color.G, $color.B)
                )
            }
        }
        return $Results -as [CompletionResult[]]
    }
    [IArgumentCompleter] Create() {
        return $this
    }
}


function Write-Color {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [ColorCompleter()]
        [ColorTransform()]
        [Drawing.Color] $ForegroundColor = 'SpringGreen',
        [ColorCompleter()]
        [ColorTransform()]
        [Drawing.Color] $BackgroundColor
    )
    begin {
        $VT = @{
            <# bold rgb text reset #>
            Foreground = "`e[1;38;2;{0};{1};{2}m{3}`e[0m"
            Background = "`e[1;48;2;{0};{1};{2}m{3}`e[0m"
            Combo      = "`e[1;38;2;{0};{1};{2};48;2;{3};{4};{5}m{6}`e[0m"
        }
    }
    process {
        if ($ForegroundColor -and $BackgroundColor) {
            return $VT.Combo -f @(1
                $ForegroundColor.R,
                $ForegroundColor.G,
                $ForegroundColor.B,
                $BackgroundColor.R,
                $BackgroundColor.G,
                $BackgroundColor.B,
                $Message
            )
        }
        if ($ForegroundColor) {
            return $VT.Foreground -f $ForegroundColor.R, $ForegroundColor.G, $ForegroundColor.B, $Message
        }
        if ($BackgroundColor) {
            return $VT.Background -f $BackgroundColor.R, $BackgroundColor.G, $BackgroundColor.B, $Message
        }
        $Message
    }
}

complete 'Write-Color -ForegroundColor dark'
# Write-Color -Message 'Hello, World!' -ForegroundColor '#4ec9b0' -BackgroundColor 'white'
# Write-Color -Message 'Hello, Universe!' -ForegroundColor 'Yellow' -BackgroundColor ([Drawing.Color]::Cyan)
# Write-Color -Message 'Hello, World!'
# ShowAttributes Write-Color
# Write-Color -BackgroundColor 'fail' -Message 'oops'
# complete 'Write-Color -ForegroundColor '
# complete 'Write-Color -ForegroundColor blue'



# Trace-Command -Expression { $null = Get-ChildItem -Path . } -Name ParameterBinding -PSHost

# Trace-Command -Expression { Write-Color 'hello' } -Name ParameterBinding -PSHost

# Trace-Command -Expression { [datetime]'2025-06-24' } -PSHost -Name TypeConversion

# fit -f ArgumentTypeConverterAttribute | emi | cs
