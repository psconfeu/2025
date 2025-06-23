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