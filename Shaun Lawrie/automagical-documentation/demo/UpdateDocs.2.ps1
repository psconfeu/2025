# Declare the module name and web app we're working with
$moduleName = "PSConf"
$websiteRoot = "./astro"

# Read in module for generating documentation
Import-Module -Name "$PSScriptRoot/$moduleName.psm1" -Force

# For each of the commands in the module generate documentation
$commands = Get-Command -Module $moduleName

# Load PlatyPS to help with markdown generation
Import-Module -Name Microsoft.PowerShell.PlatyPS

foreach ($command in $commands) {
  # Generate a command help object for the current command
  $commandHelp = New-CommandHelp $command
 
  $commandHelp.Examples | Foreach-Object {

    # Build the VHS tape input for the example, all lines that are code are sent as 'Type' commands followed by 'Enter'.
    # Comments starting with 'INPUT: ' are used to simulate user input and will be sent as verbatim VHS tape commands.
    $tapeCommands = @()
    $exampleLines = $_.Remarks -split "`n"
    foreach ($line in $exampleLines) {
      if ($line -match '^# INPUT: (.+)$') {
        # If the line starts with 'INPUT:', we simulate user input
        $tapeCommands += $matches[1]
      } elseif ($line -match '^#.*') {
        # If the line starts with a comment, we ignore it
      } else {
        # Otherwise, we treat it as a command to be typed, any single quotes will need to be doubled to escape them in the tape
        $line = $line -replace "'", "''"
        $tapeCommands += "Type '$line' Enter"
      }
      # Add a short sleep after each command to simulate thinking
      $tapeCommands += "Sleep 0.5"
    }

    # Save the example code to a tape file for Charmbracelet VHS
    Set-Content `
      -Path "tapes/$($command.Name) $($_.Title).tape" `
      -Value @"
Output "astro/public/$moduleName/$($command.Name) $($_.Title).gif"

Set Shell pwsh
Set FontSize 34
Set Width 2000
Set Height 600

Hide

Type "Import-Module ./$moduleName.psm1 -Force" Enter

Wait

Type "Clear-Host" Enter

Show

$($tapeCommands -join "`n")

Sleep 5
"@
    # Wrap the remarks in a powershell code fence
    $_.Remarks = "``````powershell`n" + $_.Remarks + "`n```````n"

    # Add a markdown image link to the example we will record
    $_.Remarks += "`n![Example](</$moduleName/$($command.Name) $($_.Title).gif>)`n"
  }

  # Generate markdown documentation for the command
  $markdownPath = Export-MarkdownCommandHelp -CommandHelp $commandHelp -OutputFolder "$websiteRoot/src/content/docs/reference/" -Force

  # Replace stuff we don't want in the markdown, I wish this could be done in the PlatyPS module
  $markdown = Get-Content -Path $markdownPath.FullName -Raw
  $markdown -replace '(?ms)^# .+?$', '' `
            -replace '(?ms)## SYNOPSIS.+?^## ', '## ' `
            -replace '(?ms)## INPUTS.+?^## ', '## ' `
            -replace '(?ms)## OUTPUTS.+?^## ', '## ' `
            -replace '(?ms)## NOTES.+?^## ', '## ' `
            -replace '(?ms)## RELATED LINKS.+', '' `
            -replace '(?ms)## SYNTAX.+?^## ', '## ' `
            -replace '(?ms)## ALIASES.+?^## ', '## ' | Set-Content -Path $markdownPath.FullName -Force
}

# Remove during demo
return

# Execute all of the VHS tapes to generate the example GIFs
Get-ChildItem -Path "tapes" -Filter "*.tape" | ForEach-Object -Parallel {
  Write-Host -ForegroundColor Green "Running tape: $($_.Name)"
  & docker run --rm -v .:/vhs vhs-pwsh "./tapes/$($_.Name)"
}