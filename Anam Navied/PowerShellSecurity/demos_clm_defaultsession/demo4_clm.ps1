# Add-Type is blocked, except for signed assembles, as it creates and loads arbitrary types
$pathToSomeDll = "C:\Users\annavied\Documents\PowerShell\Modules\Pester\4.10.1\lib\Gherkin\core\Gherkin.dll"
Add-Type -Path $pathToSomeDll
