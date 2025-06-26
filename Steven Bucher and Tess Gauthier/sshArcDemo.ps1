# SSH Arc Demo

$subscriptionID = ""
$resourceGroup = ""
$winMachineName = ""
$winUserName = ""
$pathPrivateKey = ""
$linuxMachineName = ""
$configFilePath = ""

# install Az module
Install-PSResource -Name Az -Scope AllUsers -Repository PSGallery

# verify Az module installation
Find-PSResource -Name Az

# login
Connect-AzAccount

# set active subscription
Set-AzContext -SubscriptionID $subscriptionID

# access Windows Server 2025 Arc machine with key-based authentication
# prerequisites:
# 1. generate key-pair: ssh-keygen -t ecdsa
# 2. add public key to authorized_keys or administrator_authorized_keys file on target
Enter-AzVM -ResourceGroupName $resourceGroup -Name $winMachineName -LocalUser$winUserName -PrivateKeyFile $pathPrivateKey
# with RDP parameter
Enter-AzVM -ResourceGroupName $resourceGroup -Name $winMachineName -LocalUser$winUserName -PrivateKeyFile $pathPrivateKey -RDP

# access Linux Arc machine with Entra ID authentication
# prerequisites:
# 1. install AAD extension
# az connectedmachine extension create --machine-name $linuxMachineName --resource-group $resourceGroup --publisher Microsoft.Azure.ActiveDirectory --name AADSSHLogin --type AADSSHLoginForLinux --location <location>
# 2. add RBAC for user(s): Virtual Machine User Login or Virtual Machine Administrator Login
# $objectID = (Get-AzADUser -DisplayName <username>).id
# $roleID = (Get-AzRoleDefinition -Name "Virtual Machine User Login").Id
# New-AzRoleAssignment -ObjectId $objectID -RoleDefinitionId $roleID -ResourceName $linuxMachineName -ResourceType Hybrid.Compute -ResourceGroupName $resourceGroup
Enter-AzVM -ResourceGroupName $resourceGroup -Name $linuxMachineName

# access Windows Server 2025 Arc machine via PowerShell Remoting over SSH
# prerequisites:
# Enable-PSRemoting on target
Export-AzSSHConfig -ResourceGroupName $resourceGroup -Name $winMachineName -LocalUser $winUserName -PrivateKeyFile $pathPrivateKey -ConfigFilePath $configFilePath

# save proxy info from ssh config
Get-Content $configFilePath
$options = @{ProxyCommand = 'path for ProxyCommand from $configFilePath'}

Enter-PSSession -Hostname $winMachineName -Username $winUserName -KeyFilePath $pathPrivateKey -Options $options