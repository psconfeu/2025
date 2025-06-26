New-UDApp -Content {
    New-UDButton -Text "What is happening?" -OnClick {
        Wait-Debugger
    } -ShowLoading
 }