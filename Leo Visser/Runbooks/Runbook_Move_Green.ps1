Param(
    [parameter(Mandatory = $false)]
    [string]$VmName = "GreenPowerShellAgent",

    [parameter(Mandatory = $false)]
    [string]$Subscripion = "ba4ba7c3-9670-48a1-a15d-fcfa3db37eef",

    [parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "GreenPowerShell",

    [parameter(Mandatory = $false)]
    [bool]$Move = $true,

    [parameter(Mandatory = $false)]
    [bool]$Setup = $false
)

# Functions to use
<#
.SYNOPSIS
Calculates the distance between two geographical coordinates.

.DESCRIPTION
Uses the Haversine formula to calculate the distance between two coordinates.

.PARAMETER coord1
The first set of coordinates in the format "latitude N/S, longitude E/W".

.PARAMETER coord2
The second set of coordinates in the format "latitude N/S, longitude E/W".

.OUTPUTS
[int]
Returns the distance between the two coordinates.

.EXAMPLE
CalculateDistance "40.7128 N, 74.0060 W" "37.7749 N, 122.4194 W"
Returns the distance between New York City and San Francisco.

.NOTES
Source: https://codepal.ai/code-generator/query/0kWBmveZ/powershell-function-calculate-distance
#>
function CalculateDistance {
    param (
        [string]$coord1,
        [string]$coord2
    )

    # Haversine formula to calculate distance between two coordinates
    function Haversine {
        param (
            [double]$lat1, [double]$lon1,
            [double]$lat2, [double]$lon2
        )

        $R = 3960  # Earth radius in miles

        $dLat = ($lat2 - $lat1) * [math]::PI / 180
        $dLon = ($lon2 - $lon1) * [math]::PI / 180

        $a = [math]::Sin($dLat / 2) * [math]::Sin($dLat / 2) + [math]::Cos($lat1 * [math]::PI / 180) * [math]::Cos($lat2 * [math]::PI / 180) * [math]::Sin($dLon / 2) * [math]::Sin($dLon / 2)
        $c = 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))

        $distance = $R * $c
        return $distance
    }

    # Extract latitude and longitude from the coordinates
    $coord1Parts = $coord1 -split " "
    $coord2Parts = $coord2 -split " "

    $lat1 = [double]($coord1Parts[0])
    $lon1 = [double]($coord1Parts[2])
    $lat2 = [double]($coord2Parts[0])
    $lon2 = [double]($coord2Parts[2])

    # Calculate distances in miles and convert to km
    $distance = (Haversine $lat1 $lon1 $lat2 $lon2) * 1.61

    return $distance
}

# Retrieve current region
$token = Get-AutomationVariable -Name "entsoetoken"
$From = Get-AutomationVariable -Name "curRegion"
Write-Output "1. Rerieved automation variables"

# Data to use
$geoDataEICRegions = '[{"Eic Code":"10YUA-WEPS-----0","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.2664","Longitude (generated)":"22.8343"},{"Eic Code":"10YTR-TEIAS----W","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"39.8248","Longitude (generated)":"35.6451"},{"Eic Code":"10YSK-SEPS-----K","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.7336","Longitude (generated)":"20.0542"},{"Eic Code":"10YSI-ELES-----O","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.1126","Longitude (generated)":"14.7883"},{"Eic Code":"10YRO-TEL------P","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.5240","Longitude (generated)":"25.0924"},{"Eic Code":"10YPT-REN------W","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.5677","Longitude (generated)":"-7.9739"},{"Eic Code":"10YPL-AREA-----S","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.5565","Longitude (generated)":"21.6013"},{"Eic Code":"10YNO-4--------9","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"69.0487","Longitude (generated)":"20.7979"},{"Eic Code":"10YNO-3--------J","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"63.4290","Longitude (generated)":"9.7548"},{"Eic Code":"10YNO-2--------T","COLLECT(Geo)":"Polygon","Latitude (generated)":"59.1475","Longitude (generated)":"7.3033"},{"Eic Code":"10YNO-1--------2","COLLECT(Geo)":"Polygon","Latitude (generated)":"60.6409","Longitude (generated)":"10.1607"},{"Eic Code":"10YNL----------L","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.9399","Longitude (generated)":"5.3136"},{"Eic Code":"10YMK-MEPSO----8","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.8207","Longitude (generated)":"21.3061"},{"Eic Code":"10YLV-1001A00074","COLLECT(Geo)":"Polygon","Latitude (generated)":"56.6927","Longitude (generated)":"26.6591"},{"Eic Code":"10YLT-1001A0008Q","COLLECT(Geo)":"Polygon","Latitude (generated)":"54.7820","Longitude (generated)":"24.6066"},{"Eic Code":"10YHU-MAVIR----U","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.2432","Longitude (generated)":"20.0770"},{"Eic Code":"10YHR-HEP------M","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"44.8376","Longitude (generated)":"17.3062"},{"Eic Code":"10YGR-HTSO-----Y","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"38.7320","Longitude (generated)":"23.2240"},{"Eic Code":"10YGB----------A","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"55.0024","Longitude (generated)":"-3.5392"},{"Eic Code":"10YFR-RTE------C","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"45.2365","Longitude (generated)":"4.5837"},{"Eic Code":"10YFI-1--------U","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"64.3326","Longitude (generated)":"26.6176"},{"Eic Code":"10YES-REE------0","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"40.5208","Longitude (generated)":"-3.0323"},{"Eic Code":"10YDK-2--------M","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"55.2513","Longitude (generated)":"12.2253"},{"Eic Code":"10YDK-1--------W","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"56.1105","Longitude (generated)":"9.5330"},{"Eic Code":"10YCZ-CEPS-----N","COLLECT(Geo)":"Polygon","Latitude (generated)":"49.8248","Longitude (generated)":"15.3799"},{"Eic Code":"10YCY-1001A0003J","COLLECT(Geo)":"Polygon","Latitude (generated)":"35.1240","Longitude (generated)":"33.3587"},{"Eic Code":"10YCS-SERBIATSOV","COLLECT(Geo)":"Polygon","Latitude (generated)":"44.1171","Longitude (generated)":"20.8961"},{"Eic Code":"10YCS-CG-TSO---S","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.8773","Longitude (generated)":"19.4784"},{"Eic Code":"10YCH-SWISSGRIDZ","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.6882","Longitude (generated)":"8.3111"},{"Eic Code":"10YCA-BULGARIA-R","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.9407","Longitude (generated)":"23.7983"},{"Eic Code":"10YBE----------2","COLLECT(Geo)":"Polygon","Latitude (generated)":"50.5584","Longitude (generated)":"4.5989"},{"Eic Code":"10YBA-JPCC-----D","COLLECT(Geo)":"Polygon","Latitude (generated)":"44.3487","Longitude (generated)":"17.4413"},{"Eic Code":"10YAT-APG------L","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.6155","Longitude (generated)":"13.4563"},{"Eic Code":"10YAL-KESH-----5","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.0880","Longitude (generated)":"20.2969"},{"Eic Code":"10Y1001C--000182","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.4966","Longitude (generated)":"27.9655"},{"Eic Code":"10Y1001C--00100H","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.4593","Longitude (generated)":"20.8565"},{"Eic Code":"10Y1001C--00096J","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.3685","Longitude (generated)":"16.2922"},{"Eic Code":"10Y1001A1001A990","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.1107","Longitude (generated)":"27.8897"},{"Eic Code":"10Y1001A1001A893","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.8430","Longitude (generated)":"9.3252"},{"Eic Code":"10Y1001A1001A885","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.6197","Longitude (generated)":"8.7065"},{"Eic Code":"10Y1001A1001A788","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.1945","Longitude (generated)":"16.4717"},{"Eic Code":"10Y1001A1001A82H","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.1429","Longitude (generated)":"10.4706"},{"Eic Code":"10Y1001A1001A75E","COLLECT(Geo)":"Polygon","Latitude (generated)":"37.6190","Longitude (generated)":"14.0620"},{"Eic Code":"10Y1001A1001A74G","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.8718","Longitude (generated)":"8.9731"},{"Eic Code":"10Y1001A1001A73I","COLLECT(Geo)":"Polygon","Latitude (generated)":"45.3914","Longitude (generated)":"10.2053"},{"Eic Code":"10Y1001A1001A71M","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.5293","Longitude (generated)":"13.9588"},{"Eic Code":"10Y1001A1001A70O","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"43.3700","Longitude (generated)":"11.5897"},{"Eic Code":"10Y1001A1001A59C","COLLECT(Geo)":"Polygon","Latitude (generated)":"53.4861","Longitude (generated)":"-8.2116"},{"Eic Code":"10Y1001A1001A51S","COLLECT(Geo)":"Polygon","Latitude (generated)":"53.9948","Longitude (generated)":"26.2252"},{"Eic Code":"10Y1001A1001A50U","COLLECT(Geo)":"Polygon","Latitude (generated)":"54.8787","Longitude (generated)":"21.9908"},{"Eic Code":"10Y1001A1001A48H","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"60.6763","Longitude (generated)":"6.1591"},{"Eic Code":"10Y1001A1001A47J","COLLECT(Geo)":"Polygon","Latitude (generated)":"56.5913","Longitude (generated)":"13.9205"},{"Eic Code":"10Y1001A1001A46L","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"58.6994","Longitude (generated)":"15.1505"},{"Eic Code":"10Y1001A1001A45N","COLLECT(Geo)":"Polygon","Latitude (generated)":"63.3205","Longitude (generated)":"16.6441"},{"Eic Code":"10Y1001A1001A44P","COLLECT(Geo)":"Polygon","Latitude (generated)":"67.0779","Longitude (generated)":"20.3875"},{"Eic Code":"10Y1001A1001A39I","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"58.4810","Longitude (generated)":"25.8996"}]' | ConvertFrom-Json #JSON representation of CSV data export of file found here https://www.entsoe.eu/data/energy-identification-codes-eic/eic-area-codes-map/
Write-Output "2. Loaded data"

# Connect to to Azure
$null = Connect-AzAccount -Identity -Subscription $Subscripion
Write-Output "3. Connected to Azure subscription $Subscripion"

# Get the azure Location data for the given region
$locs = get-AzLocation -ExtendedLocation:$true
$azlocs = $locs | Where-Object { $_.RegionType -eq "Physical" -and $_.GeographyGroup -eq "Europe" }

# Get the right bidding zone for every region and get the energy usage
$azureEnergy = @()

foreach ($azloc in $azlocs) {
    # Loop all bidding zones and find the closest one
    $dists = @()
    foreach ($g in $geoDataEICRegions) {
        # Calculate the distance between the centerpoint of the bidding zone and the coordinates of the Azure data center
        $dist = CalculateDistance -coord1 ($azloc.Latitude + " N " + $azloc.Longitude + " W") -coord2 ($g.'Latitude (generated)' + " N " + $g.'Longitude (generated)' + " W")

        # Store the distance in an array
        $dists += [PSCustomObject]@{
            Code     = $g.'Eic Code'
            Distance = $dist
        }
    }

    # Sort the array by distance and get the first one
    $EIC = ($dists | Sort-Object -Property Distance | Select-Object -First 1).Code

    # Determine the startdate to retrieve data (round by next hour)
    $startInterval = (Get-Date -Hour 0 -Minute 0).ToString("yyyyMMddHHmm")
    # Determine the stopdate by adding the amount of hours ahead (rounded by the hour)
    $stopInterval = (Get-Date -Minute 0).ToString("yyyyMMddHHmm")

    # Get the current energy usage
    $euri = "https://web-api.tp.entsoe.eu/api?documentType=A75&processType=A16&in_Domain=" + $EIC + "&periodStart=" + $startInterval + "&periodEnd=" + $stopInterval + "&securityToken=" + $token
    $e = Invoke-RestMethod -Uri $euri

    # Calc the green and fossil energy for usage internally
    $series = $e.GL_MarketDocument.TimeSeries | Where-Object { $_."inBiddingZone_Domain.mRID" -ne $null }
    $greenEnergy = 0
    $fossilEnergy = 0

    foreach ($s in $series) {
        if ($s.MktPSRType.psrType -in @("B01", "B09", "B10", "B11", "B12", "B13", "B14", "B15", "B16", "B17", "B18", "B19")) {
            # Renewable energy
            $greenEnergy += $s.Period.Point.quantity | Select-Object -Last 1
        }
        else {
            # Fossil energy
            $fossilEnergy += $s.Period.Point.quantity | Select-Object -Last 1
        }
    }

    # Add to array
    $azureEnergy += [PSCustomObject]@{
        Region       = $azloc.Location
        EIC          = $EIC
        GreenEnergy  = $greenEnergy
        FossilEnergy = $fossilEnergy
        Percentage   = if ($fossilEnergy -eq 0) { if ($greenEnergy -eq 0) { 0 }else { $greenEnergy } }else { $greenEnergy / $fossilEnergy }
    }
}
Write-Output "4. Found azure region energy usage:"
$azureEnergy |Sort-Object -Property Percentage -Descending | Format-Table

# Decide where to move to
$To = ($azureEnergy |Sort-Object -Property Percentage -Descending | Select-Object -First 1).Region
Write-Output "5. Move To = $To, From - $From"

if ($Setup) {
    # Register the Resource Provider
    $null = Register-AzResourceProvider -ProviderNamespace Microsoft.Migrate

    # Wait for the Resource Provider to be registered
    While (((Get-AzResourceProvider -ProviderNamespace Microsoft.Migrate) | Where-Object { $_.RegistrationState -eq "Registered" -and $_.ResourceTypes.ResourceTypeName -eq "moveCollections" } | Measure-Object).Count -eq 0) {
        Start-Sleep -Seconds 5
        Write-Output "Waiting for registration to complete."
    }
    Write-Output "-. Setup is done"
}

if ($Move -and ($To -ne $From)) {
    # Create a Mover collection
    $moverName = "GreenPowerShellMover" + ((New-Guid).Guid.Replace("-", ""))
    $null = New-AzResourceMoverMoveCollection -Name $moverName -ResourceGroupName $ResourceGroupName -SourceRegion $From -TargetRegion $To -Location "swedencentral" -IdentityType "SystemAssigned"
    Write-Output "6. Created new move collection"

    # Assign roles to the system-assigned identity of the move collection
    $moveCollection = Get-AzResourceMoverMoveCollection -SubscriptionId $Subscripion -ResourceGroupName $ResourceGroupName -Name $moverName
    $null = New-AzRoleAssignment -ObjectId ($moveCollection.IdentityPrincipalId) -RoleDefinitionName Contributor -Scope "/subscriptions/$Subscripion"
    $null = New-AzRoleAssignment -ObjectId ($moveCollection.IdentityPrincipalId) -RoleDefinitionName "User Access Administrator" -Scope "/subscriptions/$Subscripion"
    Write-Output "7. Permissions set for the move collection"

    # Add resources
    $resource = Get-AzResource -Name $VmName -ResourceGroupName $ResourceGroupName
    $targetResourceSettingsObj = New-Object Microsoft.Azure.PowerShell.Cmdlets.ResourceMover.Models.Api20230801.VirtualMachineResourceSettings
    $targetResourceSettingsObj = @{
        ResourceType       = $resource.ResourceType
        TargetResourceName = $resource.Name
    }

    Add-AzResourceMoverMoveResource -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name -SourceId $resource.ResourceId -Name "Move-$($resource.Name)" -ResourceSetting $targetResourceSettingsObj
    Write-Output "8. Added VM to move collection"

    # Add all dependencies
    while ((Resolve-AzResourceMoverMoveCollectionDependency -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name).Code -eq "MoveCollectionResolveDependenciesOperationFailed") {
        $dependencies = Get-AzResourceMoverUnresolvedDependency -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name -DependencyLevel Direct
        foreach ($d in $dependencies) {
            $resource = Get-AzResource -ResourceId $d.Id

            $targetResourceSettingsObj = @{
                ResourceType       = $resource.ResourceType
                TargetResourceName = $resource.Name
            }

            $null = Add-AzResourceMoverMoveResource -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name -SourceId $resource.ResourceId -Name "Move-$($resource.Name)" -ResourceSetting $targetResourceSettingsObj
            Write-Output "8. ** Added resource $($resource.Name) to the move collection."
        }
    }

    # Get all resources to move
    $resources = Get-AzResourceMoverMoveResource -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name
    # Create an array to track the readiness of each resource
    $resourcesready = @()
    0..($resources.count - 1) | ForEach-Object { $resourcesready += $false }

    # Keep looping the resources until all are prepared
    while ($false -in $resourcesready) {
        for ($i = 0; $i -lt $resources.count; $i++) {
            if ($resourcesready[$i] -eq $false) {
                try {
                    $prepresp = Invoke-AzResourceMoverPrepare -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name -MoveResource $resources[$i].Name -ErrorAction Stop
                    $resourcesready[$i] = $true
                    Write-Output "9. ** Prepared resource $($resources[$i].Name) for move with status $($prepresp.Status)."
                }
                catch {
                    Write-Output "9. ** Can't prepare resource $($resources[$i].Name) yet, reason: $($prepresp.Message)."
                }
            }
        }
    }

    Write-Output "9. All resources prepared"

    # Start the move
    $null = Invoke-AzResourceMoverInitiateMove -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name  -MoveResource ($resources.Id) -MoveResourceInputType "MoveResourceId"
    Write-Output "10. Move started for all resources"

    # Commit the move
    $null = Invoke-AzResourceMoverCommit -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name  -MoveResource ($resources.Id) -MoveResourceInputType "MoveResourceId"
    Write-Output "11. Commit made for all resources"

    # Remove the resources
    $null = Invoke-AzResourceMoverBulkRemove -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name  -MoveResource ($resources.Id)

    # Move the collection
    Remove-AzResourceMoverMoveCollection -ResourceGroupName $ResourceGroupName -MoveCollectionName $moveCollection.Name
    Write-Output "12. Old collections removed"

    # Store the new location
    Set-AutomationVariable -Name "curRegion" -Value $To
    Write-Output "13. From set for next run"
}