cd C:\sleet
sleet createconfig --local
code .\sleet.json

'{
  "username": "",
  "useremail": "",
  "sources": [
    {
      "name": "IIS",
      "type": "local",
      "path": "C:\\sleet\\IIS",
      "baseURI": "http://localhost:8000"
    }
  ]
}' | Out-File C:\sleet\sleet.json

sleet init 

'<configuration>
    <system.webServer>
        <staticContent>
            <mimeMap fileExtension=".nupkg" mimeType="application/zip"/>
            <mimeMap fileExtension="." mimeType="application/json"/>
        </staticContent>
    </system.webServer>
</configuration>' | Out-File C:\sleet\IIS\web.config

sleet push -s IIS "C:\sleet\modules"

Register-PSResourceRepository -Name LocalGallery -Uri http://localhost:8000/index.json -Force -trusted
Install-PSResource -Name Driscoll.Malmo -Repository LocalGallery
get-module -name Driscoll.Malmo -list
Show-MalmoHello

# Update version
Compress-PSResource 'C:\psconfeu-sleet\Driscoll.Malmo' 'C:\sleet\Modules'
ls C:\sleet\Modules
sleet push -s IIS "C:\sleet\modules\Driscoll.Malmo.0.0.2.nupkg"
Update-PSResource Driscoll.Malmo
get-module -name Driscoll.Malmo -list