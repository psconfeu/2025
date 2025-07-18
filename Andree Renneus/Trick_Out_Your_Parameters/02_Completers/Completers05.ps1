using namespace System.Collections.Generic
using namespace System.Management.Automation
class TransportCompleterAttribute: ArgumentCompleter, IArgumentCompleter, IArgumentCompleterFactory {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [Language.CommandAst] $commandAst,
        [Collections.IDictionary] $fakeBoundParameters
    ) {
        $Choices = @{
            Car        = @('Sedan', 'SUV', 'Truck')
            Motorcycle = @('Sport', 'Cruiser', 'Dirt')
            Bicycle    = @('Road', 'Mountain', 'Hybrid')
        }
        if ($fakeBoundParameters.ContainsKey('TransportType')) {
            # if we know what type we are completing, we can filter the results
            $results = foreach ($item in $Choices[$fakeBoundParameters.TransportType]) {
                if ($item -like "$wordToComplete*") {
                    [CompletionResult]::new(
                    <# completionText: #> $item,
                    <# listItemText:   #> $item,
                    <# resultType:     #> [CompletionResultType]::ParameterValue,
                    <# toolTip:        #> $item
                    )
                }
            }
        }
        else {
            $results = foreach ($item in $Choices.Values) {
                foreach ($subItem in $item) {
                    if ($subItem -like "$wordToComplete*") {
                        [CompletionResult]::new(
                        <# completionText: #> $subItem,
                        <# listItemText:   #> $subItem,
                        <# resultType:     #> [CompletionResultType]::ParameterValue,
                        <# toolTip:        #> $subItem
                        )
                    }
                }
            }
        }
        return $results -as [CompletionResult[]]
    }
    [IArgumentCompleter] Create() {
        return $this
    }
}


function Get-TestCompletion05 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Car', 'Bus','Motorcycle', 'Bicycle')]
        $TransportType,
        [Parameter(Mandatory)]
        [TransportCompleter()]
        $Value
    )
}
complete 'Get-TestCompletion05 -TransportType Bicycle -Value '
# complete 'Get-TestCompletion05 -TransportType Motorcycle -Value '
complete 'Get-TestCompletion05 -Value '
