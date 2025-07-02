function CallApi {
    param(
        $Fruit,
        [switch]$Icons
    )

    [string[]]$querystring = @()

    if (-not ([string]::IsNullOrEmpty($Fruit))) {
        $querystring += "fruit=$($Fruit -join ',')"
    }
    if ($Icons) {
        $querystring += 'icons=true'
    }

    if ($querystring.Count -gt 0) {
        (Invoke-RestMethod http://localhost:666/api?$($querystring -join '&')).result
    }
    else {
        (Invoke-RestMethod http://localhost:666/api).result
    }
}


function Get-Fruit {
    Param(
        [string]$Fruit,
        [switch]$Icons
    )

    if ($Icons) {
        $result = CallApi -Fruit $Fruit -Icons
    }
    elseif ($Fruit -eq 'peach') {
        Write-Error 'You have to move to the country to get peaches!'
    }
    else {
        $result = CallApi -Fruit $Fruit 
    }

    Write-Output $result
}
