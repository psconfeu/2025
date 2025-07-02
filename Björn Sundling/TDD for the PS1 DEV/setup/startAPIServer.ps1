Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 666 -Protocol Http

    Add-PodeRoute -Method Get -Path '/api' -ScriptBlock {
        $invokeSplat = @{}
        
        if (-not ([string]::IsNullOrEmpty($WebEvent.Query['fruit']))) {
            [string[]]$Fruit = $WebEvent.Query['fruit'].split(',')
            $invokeSplat.Add('Fruit', $Fruit)
        }

        if (-not ([string]::IsNullOrEmpty($WebEvent.Query['icons']))) {
            $invokeSplat.Add('icons', $true)
        }
                
        if (-not ([string]::IsNullOrEmpty($WebEvent.Query['sort']))) {
            $invokeSplat.Add('sort', $true)
        }

        if (-not ([string]::IsNullOrEmpty($WebEvent.Query['reversesort']))) {
            $invokeSplat.Add('ReverseSort', $true)
        }

        if ($invokeSplat.Count -gt 0) {
            $res = . $PSScriptRoot\MyApi.ps1 @invokeSplat
        }
        else {
            $res = . $PSScriptRoot\MyApi.ps1
        }

        Write-PodeJsonResponse -Value @{
            result = $res
        }
    }
}