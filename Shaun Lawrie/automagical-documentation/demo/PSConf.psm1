function Get-WelcomeMessage {
  <#
  .SYNOPSIS
    Returns a welcome message for psconfeu.
  .DESCRIPTION
    This function generates a welcome message for the psconfeu conference.
  .PARAMETER Name
    The name of the person to welcome. If not provided, it will prompt the user to enter their name.
  .EXAMPLE
    Get-WelcomeMessage -Name "Shaun"
  .EXAMPLE
    Get-WelcomeMessage
    # INPUT: Type "Shaun" Enter
  #>
  param (
      [string] $Name
  )

  if (-not $Name) {
    $Name = Read-Host "Please enter your name"
  }

  return "Welcome to psconfeu, $Name!"
}

function Get-ConferenceDate {
  <#
  .SYNOPSIS
    Returns the date of the psconfeu conference.
  .DESCRIPTION
    This function returns the date of the psconfeu conference.
  .EXAMPLE
    Get-ConferenceDate
  #>
  return "The psconfeu conference will start June 23, 2025 in Malmö."
}