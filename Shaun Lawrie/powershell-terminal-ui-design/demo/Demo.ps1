# Load an image
$containerImage = Get-SpectreImage .\images\ship.png -MaxWidth ($Host.UI.RawUI.WindowSize.Width / 3)

# Load a custom font for a title
$figlet = Write-SpectreFigletText "Containerz" -PassThru -FigletFontPath .\fonts\3d.flf

# Render the header
[ordered]@{
  Logo = $containerImage
  Text = $figlet
} | Format-SpectreTable -HideHeaders -Border None

# Main
while ($true) {
  $choices = @(
    @{
      Name = "List containers"
      Script = "ListContainers.ps1"
    },
    @{
      Name = "Start/stop containers"
      Script = "StartStopContainers.ps1"
    },
    @{
      Name = "Tail logs"
      Script = "TailLogs.ps1"
    },
    @{
      Name = "Inspect Containers"
      Script = "InspectContainers.ps1"
    },
    @{
      Name = "Exit"
    }
  )
  $choice = Read-SpectreSelection -Message "What would you like to do?" -Choices $choices -ChoiceLabelProperty "Name"

  if ($choice.Name -eq "Exit") {
    Write-SpectreHost -Message "Exiting the demo. Goodbye!"
    break
  }
  
  & "$PSScriptRoot/scripts/$($choice.Script)"
}