Remove-Item 'C:\sleet\Modules\*' -Force -Recurse
Remove-Item 'C:\Users\adamr\AppData\Local\powershell\Modules\*' -Force -Recurse
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Frame' 'C:\sleet\Modules'
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Handlebars' 'C:\sleet\Modules'
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Seat' 'C:\sleet\Modules'
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Wheel' 'C:\sleet\Modules'
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Bike' 'C:\sleet\Modules' -SkipModuleManifestValidate

ls C:\sleet\Modules

sleet push -s PSConfEUAzure "C:\sleet\Modules"
Install-PSResource -Name Driscoll.Bike -Repository PSConfEUAzure
Import-Module Driscoll.Bike

Remove-Item C:\Users\adamr\OneDrive\Documents\PowerShell\Modules\Driscoll.Bike -Recurse

Install-PSResource -Name ModuleFast 
Install-ModuleFast Driscoll.Bike -Source https://psgalleryeu.blob.core.windows.net/gallery7/index.json
Import-Module Driscoll.Bike
Show-Bike

Start-Process 'https://github.com/PowerShell/PSResourceGet/pull/1778'
