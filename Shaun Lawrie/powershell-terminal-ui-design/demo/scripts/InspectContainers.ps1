# Layout
$root = New-SpectreLayout -Name "root" -Columns @(
    New-SpectreLayout -Name "containerlist" -Ratio 1
    New-SpectreLayout -Name "inspect" -Ratio 2
)

# UI components
function Update-InspectStateComponent {
  param (
    [string] $ContainerName,
    [Spectre.Console.Layout] $Layout,
    [Spectre.Console.LiveDisplayContext] $Context
  )

  # Generate the data format
  $panel = & docker inspect $ContainerName
    | ConvertFrom-Json
    | Select-Object -ExpandProperty State
    | Format-SpectreJson
    | Format-SpectrePanel -Header "State Details" -Expand

  $Layout["inspect"].Update($panel) | Out-Null
  $Context.Refresh()
}

function Update-ContainerListComponent {
  param (
    [int] $SelectedContainerIndex,
    [string[]] $ContainerNames,
    [Spectre.Console.Layout] $Layout,
    [Spectre.Console.LiveDisplayContext] $Context
  )

  # Highlight the selected container
  for ($i = 0; $i -lt $ContainerNames.Length; $i++) {
    if ($i -eq $SelectedContainerIndex) {
      $ContainerNames[$i] = "[blue]$($ContainerNames[$i])[/]"
    }
  }

  # Format as a panel
  $panel = $ContainerNames | Format-SpectreRows | Format-SpectrePanel -Header "Container List" -Expand

  $Layout["containerlist"].Update($panel) | Out-Null
  $Context.Refresh()
}

# Live render the UI
Invoke-SpectreLive -Data $root -ScriptBlock {
  param (
    [Spectre.Console.LiveDisplayContext] $Context
  )

  # Setup data outside of main input and render loop
  $selectedContainerIndex = 0
  $containers = & docker ps --format json | ConvertFrom-Json | Select-Object -ExpandProperty Names

  while ($true) {
    if ([Console]::KeyAvailable) {
      $key = [Console]::ReadKey($true)

      if ($key.Key -eq [ConsoleKey]::UpArrow -and $selectedContainerIndex -gt 0) {
        $selectedContainerIndex--
        Update-ContainerListComponent -SelectedContainerIndex $selectedContainerIndex -ContainerNames $containers -Layout $root -Context $Context

      } elseif ($key.Key -eq [ConsoleKey]::DownArrow -and $selectedContainerIndex -lt $containers.Length - 1) {
        $selectedContainerIndex++
        Update-ContainerListComponent -SelectedContainerIndex $selectedContainerIndex -ContainerNames $containers -Layout $root -Context $Context

      } elseif ($key.Key -eq [ConsoleKey]::S) {
        # Exit rendering loop
        break
      }
    }

    # Always update the state panel
    Update-InspectStateComponent -ContainerName $containers[$selectedContainerIndex] -Layout $root -Context $Context

    Start-Sleep -Seconds 1
  }
}