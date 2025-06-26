class MyClass {
    [string]$Str 
}

$Variables["Model"] = [MyClass]::new()

function Submit {
    param($EventArgs)

    $Message.Success($EventArgs.Model.Str)
}