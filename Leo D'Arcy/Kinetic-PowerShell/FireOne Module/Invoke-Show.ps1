Param
(
    [Parameter(Mandatory)]
    [string]
    $Path,
    [switch]
    $Test,
    [switch]
    $Fire,
    [switch]
    $FireOnFailedTest
)

if (-NOT $Test -and -NOT $Fire)
{
    throw "Please use either Test or Fire switches"
}

Import-Module ImportExcel -ErrorAction Stop
Import-Module FireOne -ErrorAction Stop

$Fireworks = Import-Excel -Path $path #Import cues from excel in the format Time, Module, Cue, Description

$Fireworks = $Fireworks | Sort-Object -Property Time #Ensure that the fireworks are all in order from earliest to latest cue

#Validate that all entries have valid data prior to attempting communication with the FireOne Module
foreach ($Firework in $Fireworks)
{
    if ($null -eq $Firework.Time -or $Firework.Time.GetType() -ne [DateTime])
    {
        throw "invalid firework time entry $Firework"
    }
    if ($null -eq $Firework.Module -or $Firework.Module -lt 1 -or $Firework.Module -gt 99) #Standard Modules only support numbering up to 99
    {
        throw "invalid firework module entry $Firework"
    }
    if ($null -eq $Firework.Cue -or $Firework.Cue -lt 1 -or $Firework.Cue -gt 32) #Standard Modules only support up to 32 Cues
    {
        throw "invalid firework cue entry $Firework"
    }
    #Calculate Total seconds for each firework for easy testing during firing
    Add-Member -InputObject $Firework -NotePropertyName TotalSeconds -NotePropertyValue (((($Firework.Time.Hour * 60) + $Firework.Time.Minute) * 60) + $Firework.Time.Second)
}

if ($Test)
{
    $TestFailed = $false

    foreach ($Firework in $Fireworks)
    {
        Write-Output "Testing Firework $($Firework.Description) on Module $($Firework.Module) Cue $($Firework.Cue)"

        if ((Test-FireOneModule -Module $Firework.Module -Cue $Firework.Cue).Status)
        {
            Write-Output "Firework Successfully verified"
        }
        else
        {
            Write-Warning "Firework $($Firework.Description) on Module $($Firework.Module) Cue $($Firework.Cue) was missing"   

            $TestFailed = $true
        }
    }

    if ($Fire)
    {
        if ($TestFailed -and -NOT $FireOnFailedTest)
        {
            Write-Output "Testing Failed, exiting..."
            exit
        }

        $result = [System.Windows.Forms.MessageBox]::Show("Please put Control Panel into Fire Mode", "Firing", [System.Windows.Forms.MessageBoxButtons]::OKCancel)

        if ($result -ne [System.Windows.Forms.DialogResult]::OK)
        {
            Write-Warning "Message box canceled, exiting without firing"
            exit
        }
    }
}

if ($Fire)
{
    $Stopwatch = [System.Diagnostics.Stopwatch]::new()
    $Stopwatch.Start()

    foreach ($Firework in $Fireworks)
    {
        do
        {
            Write-Output "CurrentTime: $($Stopwatch.Elapsed.ToString()) Waiting for $($Firework.time.ToLongTimeString()) to fire $($Firework.Description)"
        } while ($Stopwatch.Elapsed.TotalSeconds -lt $Firework.TotalSeconds)

        Write-Output "Firing $($Firework.Description) at $($Stopwatch.Elapsed.ToString())"
        Invoke-FireOneExplosion -Module $Firework.Module -Cue $Firework.Cue
    }

    Write-Output "Firework Display Complete"
}
