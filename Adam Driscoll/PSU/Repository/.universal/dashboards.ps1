New-PSUApp -Name "BRB" -FilePath "dashboards\BRB\BRB.ps1" -BaseUrl "/BRB" -Authenticated -AutoDeploy 
New-PSUApp -Name "Debugging App" -FilePath "dashboards\Debugging App\Debugging App.ps1" -BaseUrl "/DebuggingApp" -Authenticated -AutoDeploy 
New-PSUApp -Name "Giphy" -FilePath "dashboards\Giphy\Giphy.ps1" -BaseUrl "/giphy" -Authenticated -AutoDeploy