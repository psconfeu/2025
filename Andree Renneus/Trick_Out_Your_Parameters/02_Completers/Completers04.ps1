using namespace System.Collections.Generic
using namespace System.Management.Automation

# works in PowerShell 5.1
class TestCompleter04 : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [Language.CommandAst] $commandAst,
        [Collections.IDictionary] $fakeBoundParameters
    ) {
        $options = @('foo', 'bar', 'woo','hello','world','random','stuff')
        $results = [List[CompletionResult]]::new()
        foreach ($entry in $options) {
            if ($entry -like "$wordToComplete*") {
                $results.Add(
                    [CompletionResult]::new(
                    <# completionText: #> $entry,
                    <# listItemText:   #> $entry,
                    <# resultType:     #> [CompletionResultType]::ParameterValue,
                    <# toolTip:        #> $entry
                ))
            }
        }
        return $results.ToArray()
    }
}

function TestCompleter04 {
    [CmdletBinding()]
    param(
        [ArgumentCompleter([TestCompleter04])]
        [string] $Name,
        [ArgumentCompleter( {
            'Malmo',
            'London',
            'Rome',
            'Amsterdam',
            'Berlin'
        })]
        [String]$City
    )
    process {
        $PSBoundParameters
    }
}
Complete 'TestCompleter04 -Name F'
Complete 'TestCompleter04 -City '
