<#
demo stickyness issue.
#>
function Test-RetriesBroken {
    [CmdletBinding()]
    param(
        [scriptblock] $Action,
        [ValidateRange(1, 10)]
        [int] $MaxRetries = 3
    )
    Write-Host "Starting retries with a maximum of $MaxRetries attempts."
    while ($MaxRetries) {
        try {
            & $Action
            return $true
        }
        catch {
            Write-Host "Attempt failed: $_"
            $MaxRetries--
            if ($MaxRetries -eq 0) {
                Write-Host 'Max retries reached. Exiting.'
                return $false
            }
            Start-Sleep -Seconds 1
        }
    }
}
Test-RetriesBroken -Action { throw 'rocks' } -ea stop


function Test-Retries {
    [CmdletBinding()]
    param(
        [scriptblock] $Action,
        [ValidateRange(1, 10)]
        [int] $MaxRetries = 3
    )
    $Retries = $MaxRetries
    Write-Host "Starting retries with a maximum of $MaxRetries attempts."
    while ($Retries) {
        try {
            & $Action
            return $true
        }
        catch {
            Write-Host "Attempt failed: $_"
            $Retries--
            if ($Retries -eq 0) {
                Write-Host "Max retries reached. Exiting."
                return $false
            }
            Start-Sleep -Seconds 1
        }
    }
}
Test-Retries -Action { throw 'rocks'} -ea Stop
