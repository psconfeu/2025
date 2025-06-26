Remove-Item C:\Users\adamr\OneDrive\Documents\PowerShell\Modules\Driscoll.Malmo -Recurse

Remove-Item C:\sleet\sleet.json -Force
cd C:\sleet
sleet createconfig --azure
code .\sleet.json

'{
  "username": "",
  "useremail": "",
  "sources": [
    {
      "name": "PSConfEUAzure",
      "type": "azure",
      "container": "gallery7",
      "connectionString": ""
    }
  ]
}' | Out-File -FilePath .\sleet.json

sleet init

sleet push -s PSConfEUAzure "C:\sleet\Modules"

Register-PSResourceRepository -Name PSConfEUAzure -Uri https://psgalleryeu.blob.core.windows.net/gallery7/index.json -Force -Trusted 
Install-PSResource -Name Driscoll.Malmo -Repository PSConfEUAzure
get-module -name Driscoll.Malmo -list