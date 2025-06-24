function Get-TestCompletion02 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
            'Hello',
            "'Hi there'"
        })]
        [string] $Greeting,
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
            [CompletionResult]::new(
                'World',
                'World',
                'ParameterValue',
                'The world'
            )
            [CompletionResult]::new(
                'Universe',
                'Universe',
                'ParameterValue',
                'The universe'
        )
        })]
        $Text
    )
}

Complete 'Get-TestCompletion02 -Greeting '
Complete 'Get-TestCompletion02 -Text '
# ShowAttributes Get-TestCompletion02
