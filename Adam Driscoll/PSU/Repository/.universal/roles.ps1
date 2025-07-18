New-PSURole -Name "Administrator" -Description "Administrators can manage settings, create and edit any entity and view all the entities with PowerShell Universal." -Policy {
param(
[Security.ClaimsPrincipal]$User
)
        
<# 
  Policies should return $true or $false to determine whether the user has the particular 
  claim that require them for that role.
#>

$false
} 
New-PSURole -Name "Execute" -Description "Execute scripts within PowerShell Universal." -Policy {
param(
[Security.ClaimsPrincipal]$User
)
        
<# 
  Policies should return $true or $false to determine whether the user has the particular 
  claim that require them for that role.
#>

$false
} 
New-PSURole -Name "Operator" -Description "Operators have access to manage and execute scripts, create other entities within PowerShell Universal but cannot manage PowerShell Universal itself." -Policy {
param(
[Security.ClaimsPrincipal]$User
)
        
<# 
  Policies should return $true or $false to determine whether the user has the particular 
  claim that require them for that role.
#>

$false
} 
New-PSURole -Name "Scheduler" -Permission @('automation.schedules/*', 'automation/read') 
New-PSURole -Name "Reader" -Description "Readers have read-only access to PowerShell Universal. They cannot make changes to any entity within the system." -Policy {
param(
[Security.ClaimsPrincipal]$User
)
        
<# 
  Policies should return $true or $false to determine whether the user has the particular 
  claim that require them for that role.
#>

$false
} 
New-PSURole -Name "User" -Description "Does not have access to the admin console but can be assigned resources like APIs, scripts, dashboards and pages." -Policy {
param(
[Security.ClaimsPrincipal]$User
)
        
<# 
  Policies should return $true or $false to determine whether the user has the particular 
  claim that require them for that role.
#>

$false
}