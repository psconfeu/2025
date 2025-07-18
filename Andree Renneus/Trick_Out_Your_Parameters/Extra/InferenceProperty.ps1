function Test-InferenceProperty {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] $InputObject,
        [ArgumentCompleter({
                param(
                    $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameter
                )
                if (-Not $fakeBoundParameter.ContainsKey('InputObject')) {
                    return
                }
                $PropertyNames = $fakeBoundParameter['InputObject'][0].PSObject.Properties.Name
                foreach ($name in $PropertyNames) {
                    if ($name -like "$wordToComplete*") {
                        [CompletionResult]::new(
                            $name,
                            $name,
                            'ParameterValue',
                            "Property: $name"
                        )
                    }
                }
            })]
        [string[]] $Properties
    )
    $PSBoundParameters
}

# fails
Complete 'Test-InferenceProperty -InputObject (Get-Process -Id $PID) -Properties '

$gps = Get-Process -Id $PID
$files = Get-ChildItem -File

# fail
Complete '$gps | Test-InferenceProperty -Properties '

# success
Complete 'Test-InferenceProperty -InputObject $files -Properties '
Complete 'Test-InferenceProperty -InputObject $gps -Properties '
