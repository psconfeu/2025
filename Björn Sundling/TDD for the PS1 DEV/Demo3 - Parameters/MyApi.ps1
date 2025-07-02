
param (
    [Parameter()]
    [ValidateSet('Apple', 'Banana', 'Kiwi', 'Salad', 'Potato')]
    [string[]]$Fruit,
    [switch]$Icons,
    [switch]$Sort,
    [switch]$ReverseSort
)
    
$r = @()
if ($Icons) {
    if (($Fruit.Count -eq 0) -or ($Fruit -contains 'Banana') -or ($Fruit -contains 'Salad')) {
        $r += '🍌'
    }
    if (($Fruit -contains 'Apple') -or ($Fruit -contains 'Salad')) {
        $r += '🍎'
    }
    if (($Fruit -contains 'Kiwi') -or ($Fruit -contains 'Salad')) {
        $r += '🥝'
    }
}
else {
    if (($Fruit.Count -eq 0) -or ($Fruit -contains 'Banana') -or ($Fruit -contains 'Salad')) {
        $r += 'Banana'
    }
    if (($Fruit -contains 'Apple') -or ($Fruit -contains 'Salad')) {
        $r += 'Apple'
    }
    if (($Fruit -contains 'Kiwi') -or ($Fruit -contains 'Salad')) {
        $r += 'Kiwi'
    }
}

if (($Fruit.Count -eq 1) -and ($Fruit -contains 'Potato')) {
    $r = '🥔'
}

if ($Sort) {
    $r | Sort-Object
}
elseif ($ReverseSort) {
    $r | Sort-Object -Descending
}
else {
    $r
}
