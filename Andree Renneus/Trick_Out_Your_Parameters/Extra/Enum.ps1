
[System.Management.Automation.ActionPreference].GetEnumValues() | ForEach-Object { '{0}: {0:d}' -f $_ }


[System.Management.Automation.CommandTypes].GetEnumValues() | ForEach-Object { '{0}: {0:d}' -f $_ }


[System.Management.Automation.CommandTypes]87 # excludes 'Cmdlet', 'Configuration', 'All'



enum Fruits {
    Apple
    Orange
    Pear
    Watermelon
}

function Get-Lunch {
    [CmdletBinding()]
    param(
        [Fruits] $Type
    )
    $PSBoundParameters
}
Complete 'Get-Lunch -Type '
Get-Lunch -Type Ap
Get-Lunch -Type C
ShowAttributes Get-Lunch


[Flags()]
enum Fruitloops {
    Apple = 1
    Orange = 2
    Pear = 4
    Watermelon = 8
    # All = 15
}

[Fruitloops]3
[Fruitloops]15
