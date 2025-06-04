Function Get-DriveInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        #add an argument completer for the drive names from win32_LogicalDisk
        [ArgumentCompleter({
                [OutputType([System.Management.Automation.CompletionResult])]
                param(
                    [string] $CommandName,
                    [string] $ParameterName,
                    [string] $WordToComplete,
                    [System.Management.Automation.Language.CommandAst] $CommandAst,
                    [System.Collections.IDictionary] $FakeBoundParameters
                )

                $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

                $DriveLetters = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID
                foreach ($DriveLetter in $DriveLetters) {
                    if ($DriveLetter -like "$WordToComplete*") {
                        $CompletionResults.Add((New-Object System.Management.Automation.CompletionResult($DriveLetter, $DriveLetter, 'ParameterValue', $DriveLetter)))
                    }
                }

                return $CompletionResults
            })]
        [ValidatePattern('^[A-Za-z]:', ErrorMessage = '{0} is an invalid drive letter.')]
        [string]$Drive = 'C:'
    )

    $data = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$Drive'"
    if ($data) {
        Write-Host "Processing $($data.Name)" -ForegroundColor Green
        # code continues ...
    }
    else {
        Write-Warning "Drive $DriveLetter not found."
    }
}