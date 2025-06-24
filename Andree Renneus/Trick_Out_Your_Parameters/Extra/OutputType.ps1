
complete 'Get-Childitem | Select-Object '

class car {
    [String] $Brand
    [String] $Model
    [String] $Color
    [Int] $Year
}

function New-Car {
    # enables type inference hints
    [OutputType([car])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $Brand,
        [Parameter(Mandatory)]
        [String] $Model,
        [String] $Color,
        [Int] $Year
    )
    [car]@{
        Brand        = $Brand
        Model        = $Model
        Color        = $Color
        Year         = $Year
    }
}

complete 'New-Car | Select-Object '
