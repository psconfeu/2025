$dockerProcesses = docker ps -a --format json | ConvertFrom-Json

function Format-DockerState {
    param (
        [string]$State
    )

    switch ($State) {
        "running" { return "[green]Running[/]" }
        "exited" { return "[red]Exited[/]" }
        default { return "[yellow]$State[/]" }
    }
}

$dockerProcesses | ForEach-Object {
    [ordered]@{
        State = Format-DockerState -State $_.State
        Names = $_.Names
        Image = $_.Image -replace '.*\/', '' # Remove repository prefix
    }
} | Format-SpectreTable -AllowMarkup -Expand -Color Grey37
