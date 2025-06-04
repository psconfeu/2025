<#
We all know that PowerShell is all about the objects. Whether you are working with files in
the console or generating custom output in a module function, you are working with objects.
But are you taking full advantage of this concept? Is the output of your command as elegant
and useful as it could be? What would make you more efficient with existing commands?
Fortunately, PowerShell has the tools to make the most of objects in the pipeline,
although many people do not take advantage of them. In this demo-heavy session, we'll
look at tools and techniques for extending and formatting objects to maximize their
usefulness and see how to incorporate them into your projects.
*Learn how to get the most value from objects in the PowerShell pipeline*
#>

#region considerations

# How will your object be consumed?
# Will it pass to another cmdlet?
# Viewed on the screen?
# Could it be serialized? How will *that* be consumed?
# Do you need to make your work in an interactive session more efficient?
# What would add value for the user with minimal effort on their part?

#endregion

#region aliases

Get-ChildItem c:\temp -File | Select-Object Name, @{Name = 'Size'; Expression = { $_.length } },
@{Name = 'Modified'; Expression = { $_.LastWriteTime } }

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

Get-ChildItem c:\temp -File | Select-Object Directory, Name, Size, Modified, ComputerName

#applies to any file object

#endregion
#region script properties

Get-ChildItem c:\temp -File | Where-Object size -GT 500 |
Select-Object Name, Modified,
@{Name = 'ModifiedAge'; Expression = { New-TimeSpan -Start $_.LastWriteTime -End (Get-Date) } }
@{Name = 'SizeKB'; Expression = { $_.size / 1kb } }

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

Get-ChildItem c:\temp -File | Where-Object size -GT 500 |
*Select-Object Name, Size, SizeKB, Modified, ModifiedAge, Computername

#script property code should run quickly but can be rich as you need
$test = {
    #test on the extension without the period
    If ($this.Extension) {
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
    else {
        'NULL'
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

Get-ChildItem c:\temp -File | Group-Object category

#endregion
#region property sets

Get-ChildItem c:\temp -File |
Select-Object FullName, Size, CreationTime, Modified, ModifiedAge

#PSTypeExtensionTools
# https://github.com/jdhitsolutions/PSTypeExtensionTools
$paramHash = @{
    Name       = 'AgeInfo'
    TypeName   = 'System.IO.FileInfo'
    Properties = 'FullName', 'Size', 'CreationTime', 'Modified', 'ModifiedAge'
    FilePath   = '.\jhFileinfo.types.ps1xml'
}
New-PSPropertySet @paramHash

psedit .\jhFileinfo.types.ps1xml

Update-TypeData -AppendPath .\jhFileinfo.types.ps1xml
Get-ChildItem -File | Get-Member -MemberType PropertySet

Get-ChildItem c:\temp -File | Select-Object AgeInfo

#endregion
#region script methods

#if you don't want to build a function to do something

# avoid using parameters
# Notice $this and not $_
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

Get-ChildItem c:\temp -File | Get-Member zip

Get-ChildItem c:\temp -File | Where-Object size -GE 1mb | ForEach-Object { $_.zip() }
#I can use parameter since I know about it. Not easily discoverable.
Get-ChildItem c:\temp -File | Where-Object size -GE 1mb | ForEach-Object { $_.zip('c:\work') }

#endregion
#region custom formatting

# needs a custom format file defined in a ps1xml file
powershell.exe -noprofile -nologo -command 'Get-ChildItem $pshome\*.format.ps1xml'

#create your own
# https://github.com/jdhitsolutions/PSScriptTools/blob/main/docs/New-PSFormatXML.md
#need a sample object with values for any property you want to use.

$paramHash = @{
    GroupBy    = 'Directory'
    Properties = 'Name', 'Size', 'CreationTime', 'Modified', 'ModifiedAge'
    viewName   = 'AgeInfo'
    formatType = 'Table'
    Path       = '.\jhFileInfo.format.ps1xml'
}

Get-Item C:\temp\a.jpg | New-PSFormatXML @paramHash
psedit .\jhFileInfo.format.ps1xml

Update-FormatData -AppendPath .\jhFileInfo.format.ps1xml
dir c:\temp -file | Format-Table -view AgeInfo

#endregion
#region incorporating into your work

#endregion