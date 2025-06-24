function Complete {
    [CmdletBinding()]
    param(
        [string]$String
    )
    (TabExpansion2 -inputScript $string -cursorColumn $string.Length).CompletionMatches
}

function ShowAttributes {
    <#
    poor mans GCP.
    #>
    [CmdletBinding()]
    param(
        [string]$CommandName
    )
    $filter = @(
        [System.Management.Automation.Cmdlet]::CommonParameters
        [System.Management.Automation.Cmdlet]::OptionalCommonParameters
    )
    $cmd = Get-Command -Name $CommandName
    foreach ($c in $cmd.ParameterSets) {
        foreach ($p in $c.Parameters) {
            if ($filter.Contains($p.Name)) {
                continue
            }
            $attribute = foreach ($attr in $p.Attributes) {
                $typeName = $attr.GetType().Name
                if ($typeName -in [Parameter].Name, 'NullableAttribute') {
                    continue
                }
                $typeName -replace 'Attribute$'
            }
            [PSCustomObject]@{
                Set        = $c.Name
                Parameter  = $p.Name
                Type       = $p.ParameterType.Name
                Attributes = $attribute -join ', '
            }
        }
    }
}
