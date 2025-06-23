[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Clean up all the demo output files for a fresh start
Remove-Item "$PSScriptRoot\tapes\*" -Force -ErrorAction SilentlyContinue

# Remove the old markdown files
Remove-Item "$PSScriptRoot\astro\src\content\docs\reference\psconf" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\docusaurus\docs\psconf" -Recurse -Force -ErrorAction SilentlyContinue

# Remove the old images
Remove-Item "$PSScriptRoot\astro\public\psconf\*.gif" -Force -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\docusaurus\static\psconf\*.gif" -Force -ErrorAction SilentlyContinue
