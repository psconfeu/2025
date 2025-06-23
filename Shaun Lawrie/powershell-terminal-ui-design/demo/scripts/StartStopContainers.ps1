$dockerContainers = docker ps -a --format json | ConvertFrom-Json

$answer = Read-SpectreSelection -Message "What operation would you like to perform?" -Choices @("Start", "Stop")

Write-SpectreHost -Message "You selected: [rapidblink blue]$answer[/]"

if ($answer -eq "Start") {
    
  $scopedContainers = $dockerContainers | Where-Object { $_.State -eq "exited" }

  if ($scopedContainers.Count -eq 0) {
    Write-SpectreHost -Message "[red]No stopped containers available to start.[/]"
    return
  }

  $targetContainers = Read-SpectreMultiSelection -Message "Select container(s) to start" -Choices $scopedContainers -ChoiceLabelProperty "Names"

  Invoke-SpectreCommandWithStatus -Spinner BoxBounce2 -Title "Starting container [blue]$($container.Names)[/]" -ScriptBlock {
    foreach ($container in $targetContainers) {
      docker start $container.ID | Out-Null
      Start-Sleep -Seconds 3 # Simulate some processing time for demonstration purposes
      Write-SpectreHost -Message ":check_mark_button: Container [blue]$($container.Names)[/] started successfully"
    }
  }

} elseif ($answer -eq "Stop") {
  $scopedContainers = $dockerContainers | Where-Object { $_.State -eq "running" }

  if ($scopedContainers.Count -eq 0) {
    Write-SpectreHost -Message "[red]No running containers available to stop.[/]"
    return
  }

  $targetContainers = Read-SpectreMultiSelection -Message "Select container(s) to stop" -Choices $scopedContainers -ChoiceLabelProperty "Names"

  Invoke-SpectreCommandWithStatus -Spinner BoxBounce2 -Title "Stopping container [blue]$($container.Names)[/]" -ScriptBlock {
    foreach ($container in $targetContainers) {
      docker stop $container.ID | Out-Null
      Start-Sleep -Seconds 3 # Simulate some processing time for demonstration purposes
      Write-SpectreHost -Message ":check_mark_button: Container [blue]$($container.Names)[/] stopped successfully"
    }
  }
} else {
    Write-SpectreHost -Message "[yellow]Invalid operation selected.[/]"
}