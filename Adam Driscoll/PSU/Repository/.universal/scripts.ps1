New-PSUScript -Name "Computer Group.ps1" -Description "Computer Group.ps1" -Path "Computer Group.ps1" 
New-PSUScript -Name "Create User" -Description "Creates a user and their mailbox." -Tag @('Onboarding') -Path "Create User.ps1" -Role @('Execute') -PortalOutputType "Table" -PortalOpenInNewWindow -Icon "user-add" -DisplayOutputOnExecute 
New-PSUScript -Name "Debugging.ps1" -Description "Debugging.ps1" -Path "Debugging.ps1" -Environment "PowerShell 7" 
New-PSUScript -Name "Demo.Tests.ps1" -Description "Demo.Tests.ps1" -Path "Demo.Tests.ps1" 
New-PSUScript -Name "Dynamic Params.ps1" -Description "Dynamic Params.ps1" -Path "Dynamic Params.ps1" 
New-PSUScript -Name "Flaky.ps1" -Description "Flaky.ps1" -Path "Flaky.ps1" 
New-PSUScript -Name "Hub.ps1" -Description "Hub.ps1" -Path "Hub.ps1" 
New-PSUScript -Name "Processes.ps1" -Description "Processes.ps1" -Path "Processes.ps1" -Role @('Execute') -PortalOutputType "Table" -PortalBehavior "LastRun" 
New-PSUScript -Name "Test.ps1" -Description "Test.ps1" -Path "Test.ps1"