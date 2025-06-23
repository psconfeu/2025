$trace = Trace-Script { 
    function Call-Dog {
        "hello"; "this"; "is"; "dog" 
    }

    Call-Dog
}

$trace.Events | 
    Format-Table -Property Timestamp, Duration, Level, Flow, Index, ReturnIndex, CallerIndex, Text
