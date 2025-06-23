$runningContainers = docker ps -a --format json | ConvertFrom-Json | Where-Object { $_.State -eq "running" }

if ($runningContainers.Count -eq 0) {
    Write-SpectreHost -Message "[red]No running containers available to tail logs.[/]"
    return
}

$targetContainer = Read-SpectreSelection -Message "Select container to tail logs" -Choices $runningContainers -ChoiceLabelProperty "Names"

$root = New-SpectreLayout -Name "root" -Rows @(
    New-SpectreLayout -Name "title" -MinimumSize 3 -Ratio 1
    New-SpectreLayout -Name "logs" -MinimumSize 5 -Ratio 5
)

# Update the title
$root["title"].Update((
  "Tailing logs for [blue]$($targetContainer.Names)[/]" | Format-SpectreAligned -HorizontalAlignment Center -VerticalAlignment Middle | Format-SpectrePanel -Expand
)) | Out-Null

function Get-DockerLogs {
  param (
    [string]$ContainerId,
    [int]$Lines = 100,
    [int]$MaxWidth = 80
  )
  $logs = docker logs $ContainerId --tail $Lines --timestamps *>&1 | Sort-Object | ForEach-Object {
    $logLine = $_.ToString()

    # Skip empty lines
    if ([string]::IsNullOrEmpty($logLine)) {
      return
    }
    
    # Trim the log line to fit within the specified width
    $logLineTrimmed = $logLine.Substring(0, [Math]::Min($logLine.Length, $MaxWidth))

    # Escape the log line for Spectre.Console
    $escapedText = $logLineTrimmed | Get-SpectreEscapedText

    # Color based on content
    switch -Wildcard ($escapedText) {
      "*error*"   { return "[red]$escapedText[/]" }
      "*warning*" { return "[Orange1]$escapedText[/]" }
      "*note*"    { return "[Grey62]$escapedText[/]" }
      "*debug*"   { return "[Grey62]$escapedText[/]" }
      default     { return "[white]$escapedText[/]" }
    }
  }

  # Add a final line with a note to press Ctrl+C to stop
  $logs += "Press [red]S[/] to stop tailing logs."

  return $logs
}

Invoke-SpectreLive -Data $root -ScriptBlock {
  param (
    [Spectre.Console.LiveDisplayContext] $Context
  )

  while ($true) {
    $layoutSize = Get-SpectreLayoutSizes -Layout $root
    $logsHeight = $layoutSize["logs"].Height - 3 # subtract 2 for border and 1 for final line
    $logWidth = $layoutSize["logs"].Width - 10 # subtract 2 for border, 10 for luck
  
    # Get the docker logs for the selected container
    $logs = Get-DockerLogs -ContainerId $targetContainer.ID -Lines $logsHeight -MaxWidth $logWidth

    $root["logs"].Update((
     $logs | Format-SpectreRows | Format-SpectrePanel -Expand
    )) | Out-Null
  
    $Context.Refresh()
  
    Start-Sleep -Seconds 1

    # Check if key was pressed and if it was S to stop tailing logs
    if ([Console]::KeyAvailable) {
      $key = [Console]::ReadKey($true)
      if ($key.Key -eq [ConsoleKey]::S) {
        break
      }
    }
  }
}