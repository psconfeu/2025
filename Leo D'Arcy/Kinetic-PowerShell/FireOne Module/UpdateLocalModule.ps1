#This script is designed for local deveopment work, it builds the module,
#then loads it into the current session by working out the compiled source location and directly forcing an import or copying the module to the user's module location and loading from there

$CopyToLocalComputer = $true

Import-Module ModuleBuilder -WarningAction SilentlyContinue

$BuildSettings = Import-PowerShellDataFile -Path "Build.psd1" -ErrorAction Stop

if ($null -ne $BuildSettings.OutputDirectory)
{
    if ($PSScriptRoot.StartsWith($BuildSettings.OutputDirectory))
    {
        Write-Warning "Not clearing Output Directory as it may be the original source location"
    }
    elseif ($BuildSettings.OutputDirectory.StartsWith($Env:windir))
    {
        Write-Warning "Not clearing Output Directory as it may be in a critical system path location"
    }
    else
    {
        Write-Output "Clearing $($BuildSettings.OutputDirectory)"
        Remove-Item -Path $BuildSettings.OutputDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }   
}

#Increment Build Number
$ModuleData = Import-PowerShellDataFile -Path $BuildSettings.Path
$CurrentVersionString = $ModuleData.ModuleVersion
$CurrentVersion = [Version]::Parse($CurrentVersionString)
if ($null -ne $CurrentVersion)
{
    $NewVersion = [Version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build, $CurrentVersion.Revision + 1)

    $ModuleDataFile = Get-Content -Path $BuildSettings.Path
    Foreach ($line in $ModuleDataFile)
    {
        if ($line.StartsWith('ModuleVersion'))
        {
            $ModuleDataFile[$ModuleDataFile.IndexOf($line)] = "ModuleVersion = '$($NewVersion.ToString())'"
            break
        }
    }
    Set-Content -Path $BuildSettings.Path -Value $ModuleDataFile
}

Build-Module

#ZIP the module for easy upload
Compress-Archive -Path $BuildSettings.OutputDirectory -DestinationPath $BuildSettings.OutputDirectory.Trim('\') -Force

$ModuleDir = Join-Path -Path $BuildSettings.OutputDirectory -ChildPath $NewVersion.ToString()
$ModulePath = Join-Path -Path $ModuleDir -ChildPath FireOne.psd1
Disconnect-FireOnePanel -ErrorAction SilentlyContinue #Attempt a panel Disconnect to avoid the connection being lost and needing a restart

if ($CopyToLocalComputer)
{
    $LocalModuleDir = $env:psmodulepath.Split(";") | Where-Object { $_.startswith([Environment]::GetFolderPath('MyDocuments')) }
    $ModuleName = Split-Path -Path (Split-Path -Path $ModuleDir) -Leaf
    $DestinationDir = Join-Path -Path $LocalModuleDir -ChildPath $ModuleName
    if (-NOT (Test-Path -Path $DestinationDir))
    {
        New-Item -Path $DestinationDir -ItemType Directory
    }
    Copy-Item -Path $ModuleDir -Destination $DestinationDir -Recurse
    Import-Module -Name $ModuleName -ErrorAction Stop
}
else
{
    #Import the latest version directly from the build location
    Import-Module -Name $ModulePath -Force
}

