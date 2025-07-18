# does not work in PowerShell 5.1

function Get-TestCompletion01 {
    [CmdletBinding()]
    param(
        # equivilant of ValidateSet but without the validation.
        [ArgumentCompletions('Anna', 'Steve', 'Emily')]
        [String] $Manager
    )
    $PSBoundParameters
}

Complete 'Get-TestCompletion01 -Manager '
Complete 'Get-TestCompletion01 -Manager A'

Get-TestCompletion01 foo

ShowAttributes Get-TestCompletion01
