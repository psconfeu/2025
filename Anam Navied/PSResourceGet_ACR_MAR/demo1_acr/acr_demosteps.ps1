Get-Module "Microsoft.PowerShell.PSResourceGet"
#to authenticate- I use the Az commands to re-authenticate for demonstration purposes, but using the Az module is not neccessary as PSResourceGet will prompt for login alone if you are not already authenticated
Get-Module "Az"

# Sign in and authenticate to the subscription
Connect-AzAccount -Subscription "MySubscription"

New-AzResourceGroup -Name "rg-PSConfEUDemoLive" -Location "EastUS"

New-AzContainerRegistry -ResourceGroupName "rg-PSConfEUDemoLive" -Name "crPSConfEUDemo" -EnableAdminUser -Sku Standard -Location EastUS

# check creation in portal, grab login server, or use Az cmdlet below
$myAcr = Get-AzContainerRegistry -Name "crPSConfEUDemo" -ResourceGroupName "rg-PSConfEUDemoLive"
$acrUrl = "https://$($myAcr.LoginServer)"

Register-PSResourceRepository -Name "ACRDemo" -Uri $acrUrl
Get-PSResourceRepository -Name "ACRDemo" | fl *

# Publish a module to ACR:
mkdir demo_testmodule

New-ModuleManifest -Path ".\demo_testmodule\demo_testmodule.psd1" -Description "module for demo"
Publish-PSResource -Path .\demo_testmodule\ -Repository "ACRDemo"

# Find the module from ACR:
Find-PSResource "demo_testmodule" -Repository "ACRDemo" | fl *

# Install the module from ACR:
Install-PSResource "demo_testmodule" -Repository "ACRDemo" -TrustRepository
Get-PSResource "demo_testmodule"

# View your module in your container registry in the Microsoft Azure Portal