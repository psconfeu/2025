

$trace = Trace-Script { 
    function Hello ($number) {
        if ($number -gt 50) {
            return
        }
        Start-Sleep -Milliseconds 15

        Hello ($number + 1) 
    }    

    Hello -Number 0
}

# Wrong!
$duration = [timespan]::Zero
foreach ($event in $trace.Events | Where-Object Text  -LIKE "Hello*") {
    $duration += $event.Duration
}
"BROKEN: 
Hello function took: $($duration.TotalMilliseconds) ms
Whole script took: $($trace.StopwatchDuration.TotalMilliseconds) ms"

# Correct!
$hello = $trace.Events | Where-Object Text  -LIKE "Hello*" |  Select-Object -First 1 
$return = $trace.Events[$hello.ReturnIndex]

$correctDuration = $return.StartTime - $hello.StartTime

"
CORRECT: 
Hello function took: $($correctDuration.TotalMilliseconds) ms
Whole script took: $($trace.StopwatchDuration.TotalMilliseconds) ms"

# $trace.Events | 
#     Format-Table -Property Timestamp, Duration, Level, Flow, Index, ReturnIndex, CallerIndex, Text
