# core scripting features, like arrays, loops, conditional flow, operators, variables are all good
$numbers = @(1..10)
$evenNums = 0

foreach ($number in $numbers) {
    if ($number % 2 -eq 0) {
        $evenNums++
    }
}

Write-Verbose -Verbose "core scripting works"