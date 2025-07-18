param($AppToken)

Task InstallModules {
    @("PowerShellUniversal.HealthCheck.InternetAccess", "PowerShellUniversal.API.System") | ForEach-Object {
        if (-not (Test-Path ("$PSScriptRoot\Deployment\Modules\$_"))) {
            Save-PSResource -Name $_ -Path "$PSScriptRoot\Deployment\Modules" 
        }
        
    }
}

Task CompressFiles {
    Remove-Item -Path "$PSScriptRoot\PSUDeployment.*.nupkg" -ErrorAction Ignore
    Compress-PSResource -Path "$PSScriptRoot\Deployment" -Destination "$PSScriptRoot"
}

Task Publish {
    Invoke-RestMethod http://localhost:5000/api/v1/deployment -Method PUT -Headers @{
        Authorization = "Bearer $AppToken"
    } -InFile "$PSScriptRoot\PSUDeployment.*.nupkg"
}

Task . InstallModules, CompressFiles, Publish