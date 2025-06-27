$newUser = @{
    'Name' = 'PSConfEU 2025'
    'SamAccountName' = 'psconfeu25'
    'AccountPassword' = ('RobIsGre@t!' | ConvertTo-SecureString -AsPlainText -Force)
    'Enabled' = $true
    'Path' = 'OU=_TEST,OU=LAB,DC=child,DC=mega,DC=korp'
    'DisplayName' = 'PSConfEU 2025'
    'UserPrincipalName' = 'psconfeu25@child.mega.korp'
}
New-ADUser @newUser
[System.Security.Principal.WindowsIdentity]::new($newUser.UserPrincipalName).Name