# Unapproved .NET types are not allowed, they could use arbitrary code or APIs!
# -> System.IO.FileInfo is not an approved type

$fileInfo = [System.IO.FileInfo]::new("C:\Windows\notepad.exe")