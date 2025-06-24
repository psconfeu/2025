function Get-TestValidation01 {
    [CmdletBinding()]
    param(
        [ValidateSet('Alice', 'Bob', 'Charlie', ErrorMessage = 'Ooops "{0}", did you mean {1} ?')]
        [string] $Name,
        [ValidateRange(0, 30)]
        [int] $Age,
        [ValidatePattern('^[a-z]+$', ErrorMessage = '{0} does not match pattern {1}')]
        [string] $City,
        [ValidateLength(1, 10)]
        [string] $Country,
        [ValidateScript({ $_ -match '^[a-z]+$' }, ErrorMessage = '{0} invalid, Script => {1}')]
        [string] $State,
        [ValidateNotNullOrWhiteSpace()]
        [string] $StreetAddress
    )
    $PSBoundParameters
    # show stickyness
    # $Name = 'Steve'
    # solution, use a new variable
    # $NewName = $name
    # $NewName = 'steve'
}

Get-TestValidation01 -Name Alice

# Get-TestValidation01 -City 'NewYork' #-ZipCode '12345'
# Get-TestValidation01 -City W01w
# ShowAttributes Get-TestValidation01

<#
[ValidateSet]::new
[ValidateRange]::new
[ValidatePattern]::new
[ValidateScript]::new
#>
