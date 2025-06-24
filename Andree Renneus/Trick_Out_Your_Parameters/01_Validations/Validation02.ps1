using namespace System.Management.Automation
class Shapes : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return 'Circle', 'Square', 'Hexagon', 'Triangle', 'Pentagon', 'Octagon'
    }
}

function Get-Shapes {
    param(
        [ValidateSet([Shapes], ErrorMessage = '{0} is not an approved shape, try one of the following: {1}')]
        [string] $Shapes
    )
    $PSBoundParameters
}
complete 'Get-Shapes -Shapes '
# Get-Shapes -Shapes Star
