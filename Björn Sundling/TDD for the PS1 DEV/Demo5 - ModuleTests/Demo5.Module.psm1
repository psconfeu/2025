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
    else {
        $result = CallApi -Fruit $Fruit 
    }

    Write-Output $result
}

function Get-FruitSalad {
    Param(
        [switch]$icons
    )
    
    if ($Icons) {
        $result = CallApi -Fruit 'Salad' -Icons
    }
    else {
        $result = CallApi -Fruit 'Salad' 
    }

    Write-Output $result
}

# Export-ModuleMember @('Get-Fruit', 'Get-FruitSalad')