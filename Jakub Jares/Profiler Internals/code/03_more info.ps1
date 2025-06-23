$sb = { "hello"; "this"; "is"; "dog" }

try {
    Set-PSDebug -Trace 1
    & $sb
}
finally {
    Set-PSDebug -Off
}

$sb | Format-List * -Force
