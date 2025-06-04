#requires -version 7.5

$params = @{
    TypeName   = 'System.IO.FileInfo'
    MemberType = 'AliasProperty'
    MemberName = 'Size'
    Value      = 'Length'
    Force      = $True
}
Update-TypeData @params

$params.MemberName = 'Modified'
$params.Value = 'LastWriteTime'
Update-TypeData @params

#this might be useful if serializing
$params.MemberType = 'NoteProperty'
$params.MemberName = 'Computername'
$params.Value = [System.Environment]::MachineName
Update-TypeData @params

$params = @{
    TypeName   = 'System.IO.FileInfo'
    MemberType = 'ScriptProperty'
    MemberName = 'ModifiedAge'
    Value      = { New-TimeSpan -Start $this.LastWriteTime -End (Get-Date) }
    Force      = $True
}
Update-TypeData @params

$params.MemberName = 'SizeKB'
$params.value = { $this.Length / 1KB }
Update-TypeData @params

$test = {
    #test on the extension without the period
    Switch -regex ($this.Extension.Substring(1)) {
        '^ps(d)?1(xml)?' { 'PowerShell' }
        '^(bmp|jp(e)?g|png|gif|tiff)' { 'Image' }
        '^(mp3|mp4|m4v)' { 'Media' }
        '^(xml|json|csv|yml|yaml)' { 'Data' }
        '^(md|pdf|doc(x)?|htm(l)?|txt)' { 'Document' }
        '^(zip|tar|gz|bz2|7z)' { 'Archive' }
        '^(exe|dll|bat|cmd|com|pdb)' { 'System' }
        default { 'File' }
    }
}

$params = @{
    TypeName   = 'System.IO.FileInfo'
    MemberType = 'ScriptProperty'
    MemberName = 'Category'
    Value      = $test
    Force      = $True
}
Update-TypeData @params

$zip = {
    Param([string]$Destination = $this.Directory)
    $target = Join-Path -Path $Destination -ChildPath "$($this.baseName).zip"
    $paramHash = @{
        Path             = $this.FullName
        DestinationPath  = $target
        CompressionLevel = 'Optimal'
        Force            = $True
        PassThru         = $True
    }

    Compress-Archive @paramHash
}
$params = @{
    TypeName   = 'System.IO.FileInfo'
    MemberType = 'ScriptMethod'
    MemberName = 'Zip'
    Value      = $zip
    Force      = $True
}
Update-TypeData @params

Update-TypeData -AppendPath $PSScriptRoot\jhFileinfo.types.ps1xml
Update-FormatData -AppendPath $PSScriptRoot\jhFileInfo.format.ps1xml
