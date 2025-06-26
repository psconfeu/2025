param(
    [Parameter(Mandatory, HelpMessage = "The user name")]
    $UserName,
    [Parameter(Mandatory, HelpMessage = "The user's last name")]
    $FirstName,
    [Parameter(Mandatory, HelpMessage = "The user's first name")]
    $LastName,
    [Parameter(Mandatory, HelpMessage = "The default password.")]
    [string]$Password,
    [Parameter(Mandatory, HelpMessage = "Confirm the default password")]
    [string]$ConfirmPassword,
    [Parameter(HelpMessage = "A department the user is a part of.")]
    [ValidateSet("HR", "Development", "Marketing")]
    [string]$Department
)

@{
    UserName = $UserName 
    DateCreate = (Get-Date)
    FirstName = $FirstName 
    LastName = $LastName 
    Department = $Department 
}