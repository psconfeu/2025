Param(
     [parameter(Mandatory=$false)]
     [string]$Region = "westeurope",

     [parameter(Mandatory=$false)]
     [string]$Subscripion = "ba4ba7c3-9670-48a1-a15d-fcfa3db37eef",

     [parameter(Mandatory=$false)]
     [string]$AutomationAccountName = "GreenPowerShell",

     [parameter(Mandatory=$false)]
     [string]$ResourceGroupName = "GreenPowerShell",

     [parameter(Mandatory=$false)]
     [int]$HoursAhead = 24
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

# Data to use
$geoDataEICRegions = '[{"Eic Code":"10YUA-WEPS-----0","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.2664","Longitude (generated)":"22.8343"},{"Eic Code":"10YTR-TEIAS----W","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"39.8248","Longitude (generated)":"35.6451"},{"Eic Code":"10YSK-SEPS-----K","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.7336","Longitude (generated)":"20.0542"},{"Eic Code":"10YSI-ELES-----O","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.1126","Longitude (generated)":"14.7883"},{"Eic Code":"10YRO-TEL------P","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.5240","Longitude (generated)":"25.0924"},{"Eic Code":"10YPT-REN------W","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.5677","Longitude (generated)":"-7.9739"},{"Eic Code":"10YPL-AREA-----S","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.5565","Longitude (generated)":"21.6013"},{"Eic Code":"10YNO-4--------9","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"69.0487","Longitude (generated)":"20.7979"},{"Eic Code":"10YNO-3--------J","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"63.4290","Longitude (generated)":"9.7548"},{"Eic Code":"10YNO-2--------T","COLLECT(Geo)":"Polygon","Latitude (generated)":"59.1475","Longitude (generated)":"7.3033"},{"Eic Code":"10YNO-1--------2","COLLECT(Geo)":"Polygon","Latitude (generated)":"60.6409","Longitude (generated)":"10.1607"},{"Eic Code":"10YNL----------L","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.9399","Longitude (generated)":"5.3136"},{"Eic Code":"10YMK-MEPSO----8","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.8207","Longitude (generated)":"21.3061"},{"Eic Code":"10YLV-1001A00074","COLLECT(Geo)":"Polygon","Latitude (generated)":"56.6927","Longitude (generated)":"26.6591"},{"Eic Code":"10YLT-1001A0008Q","COLLECT(Geo)":"Polygon","Latitude (generated)":"54.7820","Longitude (generated)":"24.6066"},{"Eic Code":"10YHU-MAVIR----U","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.2432","Longitude (generated)":"20.0770"},{"Eic Code":"10YHR-HEP------M","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"44.8376","Longitude (generated)":"17.3062"},{"Eic Code":"10YGR-HTSO-----Y","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"38.7320","Longitude (generated)":"23.2240"},{"Eic Code":"10YGB----------A","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"55.0024","Longitude (generated)":"-3.5392"},{"Eic Code":"10YFR-RTE------C","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"45.2365","Longitude (generated)":"4.5837"},{"Eic Code":"10YFI-1--------U","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"64.3326","Longitude (generated)":"26.6176"},{"Eic Code":"10YES-REE------0","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"40.5208","Longitude (generated)":"-3.0323"},{"Eic Code":"10YDK-2--------M","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"55.2513","Longitude (generated)":"12.2253"},{"Eic Code":"10YDK-1--------W","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"56.1105","Longitude (generated)":"9.5330"},{"Eic Code":"10YCZ-CEPS-----N","COLLECT(Geo)":"Polygon","Latitude (generated)":"49.8248","Longitude (generated)":"15.3799"},{"Eic Code":"10YCY-1001A0003J","COLLECT(Geo)":"Polygon","Latitude (generated)":"35.1240","Longitude (generated)":"33.3587"},{"Eic Code":"10YCS-SERBIATSOV","COLLECT(Geo)":"Polygon","Latitude (generated)":"44.1171","Longitude (generated)":"20.8961"},{"Eic Code":"10YCS-CG-TSO---S","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.8773","Longitude (generated)":"19.4784"},{"Eic Code":"10YCH-SWISSGRIDZ","COLLECT(Geo)":"Polygon","Latitude (generated)":"46.6882","Longitude (generated)":"8.3111"},{"Eic Code":"10YCA-BULGARIA-R","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.9407","Longitude (generated)":"23.7983"},{"Eic Code":"10YBE----------2","COLLECT(Geo)":"Polygon","Latitude (generated)":"50.5584","Longitude (generated)":"4.5989"},{"Eic Code":"10YBA-JPCC-----D","COLLECT(Geo)":"Polygon","Latitude (generated)":"44.3487","Longitude (generated)":"17.4413"},{"Eic Code":"10YAT-APG------L","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.6155","Longitude (generated)":"13.4563"},{"Eic Code":"10YAL-KESH-----5","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.0880","Longitude (generated)":"20.2969"},{"Eic Code":"10Y1001C--000182","COLLECT(Geo)":"Polygon","Latitude (generated)":"48.4966","Longitude (generated)":"27.9655"},{"Eic Code":"10Y1001C--00100H","COLLECT(Geo)":"Polygon","Latitude (generated)":"42.4593","Longitude (generated)":"20.8565"},{"Eic Code":"10Y1001C--00096J","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.3685","Longitude (generated)":"16.2922"},{"Eic Code":"10Y1001A1001A990","COLLECT(Geo)":"Polygon","Latitude (generated)":"47.1107","Longitude (generated)":"27.8897"},{"Eic Code":"10Y1001A1001A893","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.8430","Longitude (generated)":"9.3252"},{"Eic Code":"10Y1001A1001A885","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.6197","Longitude (generated)":"8.7065"},{"Eic Code":"10Y1001A1001A788","COLLECT(Geo)":"Polygon","Latitude (generated)":"40.1945","Longitude (generated)":"16.4717"},{"Eic Code":"10Y1001A1001A82H","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"51.1429","Longitude (generated)":"10.4706"},{"Eic Code":"10Y1001A1001A75E","COLLECT(Geo)":"Polygon","Latitude (generated)":"37.6190","Longitude (generated)":"14.0620"},{"Eic Code":"10Y1001A1001A74G","COLLECT(Geo)":"Polygon","Latitude (generated)":"39.8718","Longitude (generated)":"8.9731"},{"Eic Code":"10Y1001A1001A73I","COLLECT(Geo)":"Polygon","Latitude (generated)":"45.3914","Longitude (generated)":"10.2053"},{"Eic Code":"10Y1001A1001A71M","COLLECT(Geo)":"Polygon","Latitude (generated)":"41.5293","Longitude (generated)":"13.9588"},{"Eic Code":"10Y1001A1001A70O","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"43.3700","Longitude (generated)":"11.5897"},{"Eic Code":"10Y1001A1001A59C","COLLECT(Geo)":"Polygon","Latitude (generated)":"53.4861","Longitude (generated)":"-8.2116"},{"Eic Code":"10Y1001A1001A51S","COLLECT(Geo)":"Polygon","Latitude (generated)":"53.9948","Longitude (generated)":"26.2252"},{"Eic Code":"10Y1001A1001A50U","COLLECT(Geo)":"Polygon","Latitude (generated)":"54.8787","Longitude (generated)":"21.9908"},{"Eic Code":"10Y1001A1001A48H","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"60.6763","Longitude (generated)":"6.1591"},{"Eic Code":"10Y1001A1001A47J","COLLECT(Geo)":"Polygon","Latitude (generated)":"56.5913","Longitude (generated)":"13.9205"},{"Eic Code":"10Y1001A1001A46L","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"58.6994","Longitude (generated)":"15.1505"},{"Eic Code":"10Y1001A1001A45N","COLLECT(Geo)":"Polygon","Latitude (generated)":"63.3205","Longitude (generated)":"16.6441"},{"Eic Code":"10Y1001A1001A44P","COLLECT(Geo)":"Polygon","Latitude (generated)":"67.0779","Longitude (generated)":"20.3875"},{"Eic Code":"10Y1001A1001A39I","COLLECT(Geo)":"MultiPolygon","Latitude (generated)":"58.4810","Longitude (generated)":"25.8996"}]' | ConvertFrom-Json #JSON representation of CSV data export of file found here https://www.entsoe.eu/data/energy-identification-codes-eic/eic-area-codes-map/
$psrType = '[{"Code":"A03","Meaning":"Mixed"},{"Code":"A04","Meaning":"Generation"},{"Code":"A05","Meaning":"Load"},{"Code":"B01","Meaning":"Biomass"},{"Code":"B02","Meaning":"Fossil Brown coal/Lignite"},{"Code":"B03","Meaning":"Fossil Coal-derived gas"},{"Code":"B04","Meaning":"Fossil Gas"},{"Code":"B05","Meaning":"Fossil Hard coal"},{"Code":"B06","Meaning":"Fossil Oil"},{"Code":"B07","Meaning":"Fossil Oil shale"},{"Code":"B08","Meaning":"Fossil Peat"},{"Code":"B09","Meaning":"Geothermal"},{"Code":"B10","Meaning":"Hydro Pumped Storage"},{"Code":"B11","Meaning":"Hydro Run-of-river and poundage"},{"Code":"B12","Meaning":"Hydro Water Reservoir"},{"Code":"B13","Meaning":"Marine"},{"Code":"B14","Meaning":"Nuclear"},{"Code":"B15","Meaning":"Other renewable"},{"Code":"B16","Meaning":"Solar"},{"Code":"B17","Meaning":"Waste"},{"Code":"B18","Meaning":"Wind Offshore"},{"Code":"B19","Meaning":"Wind Onshore"},{"Code":"B20","Meaning":"Other"},{"Code":"B21","Meaning":"AC Link"},{"Code":"B22","Meaning":"DC Link"},{"Code":"B23","Meaning":"Substation"},{"Code":"B24","Meaning":"Transformer"},{"Code":"B25","Meaning":"Energy storage"}]' | ConvertFrom-Json # JSON representation of table found here https://transparencyplatform.zendesk.com/hc/en-us/articles/15856995130004-PsrType

# Get automation variables
$token = Get-AutomationVariable -Name "entsoetoken"
Write-Output "1. Retrieved automation variables"

# Connect to Azure
$null = Connect-AzAccount -Identity -Subscription $Subscripion
Write-Output "2. Connected to Azure"

# Get the azure Location data for the given region
$locs = get-AzLocation -ExtendedLocation:$true
$azloc = $locs | Where-Object { $_.Location -eq $Region }
Write-Output "3. Found Azure region ($($azloc.DisplayName)) for given Region and retrieved data."

# Loop all bidding zones and find the closest one
$dists = @()
foreach($g in $geoDataEICRegions){
    # Calculate the distance between the centerpoint of the bidding zone and the coordinates of the Azure data center
    $dist = CalculateDistance -coord1 ($azloc.Latitude + " N " + $azloc.Longitude+" W") -coord2 ($g.'Latitude (generated)' + " N " + $g.'Longitude (generated)'+" W")

    # Store the distance in an array
    $dists += [PSCustomObject]@{
        Code = $g.'Eic Code'
        Distance = $dist
    }
}
# Sort the array by distance and get the first one
$EIC = ($dists | Sort-Object -Property Distance | Select-Object -First 1).Code
Write-Output "4. Found the closest EIC code ($EIC)."

# Determine the startdate to retrieve data (round by next hour)
$startInterval = (Get-Date -Minute 0).AddHours(1).ToString("yyyyMMddHHmm")
# Determine the stopdate by adding the amount of hours ahead (rounded by the hour)
$stopInterval = (Get-Date -Minute 0).AddHours($HoursAhead).AddHours(1).ToString("yyyyMMddHHmm")

# Get wind and solar forecast
$greenuri = "https://web-api.tp.entsoe.eu/api?documentType=A69&processType=A01&in_Domain="+$EIC+"&periodStart="+$startInterval+"&periodEnd="+$stopInterval+"&securityToken="+$token
$green = Invoke-RestMethod -Uri $greenuri
Write-Output "5. Retrieved $($green.GL_MarketDocument.TimeSeries.Period.Point.count) data points for Wind and Solar forecast"

# Get total forecast
$alluri = "https://web-api.tp.entsoe.eu/api?documentType=A71&processType=A01&in_Domain="+$EIC+"&periodStart="+$startInterval+"&periodEnd="+$stopInterval+"&securityToken="+$token
$all = Invoke-RestMethod -Uri $alluri
Write-Output "6. Retrieved $($all.GL_MarketDocument.TimeSeries.Period.Point.count) data points for general forecast"

# Gather all the types of energy and calculate the non-green use of energy
$Energy = @()
$startTimeDataSet = Get-Date ($all.GL_MarketDocument.TimeSeries.Period[0].timeInterval.start)

for ($t=0; $t -lt $all.GL_MarketDocument.TimeSeries.count; $t++) {
    for ($i=0; $i -lt $all.GL_MarketDocument.TimeSeries[$t].Period.Point.count; $i++) {

        # Increment the time for every Timeseries and point
        $time = $startTimeDataSet.AddMinutes(($i + ($t* $all.GL_MarketDocument.TimeSeries[$t].Period.Point.count)) * [System.Xml.XmlConvert]::ToTimeSpan(($all.GL_MarketDocument.TimeSeries.Period | Select-Object -First 1).resolution).TotalMinutes)

        if($time -gt ((Get-Date -Minute 0).AddHours(1)) -and $time -lt ((Get-Date -Minute 0).AddHours($HoursAhead).AddHours(1))) {
            # Variables to store data in loops
            $GreenExpected = 0

            # Create an object to store the energy data
            $eObject = [PSCustomObject]@{
                Time = $time
            }

            # Filter the dataset that is for the current time
            $curGreen = $green.GL_MarketDocument.TimeSeries | Where-Object {(Get-Date $_.Period.timeInterval.start) -le $time -and (Get-Date $_.Period.timeInterval.end) -gt $time}
            $curAll = $all.GL_MarketDocument.TimeSeries | Where-Object {(Get-Date $_.Period.timeInterval.start) -le $time -and (Get-Date $_.Period.timeInterval.end) -gt $time}

            # Add the total energy
            $eObject | Add-Member -MemberType NoteProperty -Name "TotalExpected" -Value $curAll.Period.Point[$i].Quantity

            # Loop through all types of green energy and store them in the object and add all green energy together
            for($j=0; $j -lt $curGreen.count; $j++) {
                # Store the value for this type
                $eObject | Add-Member -MemberType NoteProperty -Name "Green Energy ($(($psrType | Where-Object {$_.Code -eq $curGreen[$j].MktPSRType.psrType}).Meaning))" -Value ([int]$curGreen[$j].Period.Point[$i].Quantity)
                # Add all green energy together
                $greenExpected += [int]$curGreen[$j].Period.Point[$i].Quantity
                Write-Host "Time = $time, $t = $t, $i = $i, $j = $j, name = $(($psrType | Where-Object {$_.Code -eq $curGreen[$j].MktPSRType.psrType}).Meaning), value = $([int]$curGreen[$j].Period.Point[$i].Quantity)"
            }
            # Add the total green energy
            $eObject | Add-Member -MemberType NoteProperty -Name "GreenExpected" -Value $greenExpected

            # Add the total fossil energy
            $eObject | Add-Member -MemberType NoteProperty -Name "FossilExpected" -Value ([int]$curAll.Period.Point[$i].Quantity - $greenExpected)

            # Add the object to the array
            $Energy += $eObject
        }
    }
}
Write-Output "7. Gathered energy information"
$Energy | Format-Table

# Find the best slot
$slot = $Energy | Where-Object {$_.TotalExpected -gt 0} | Sort-Object -Property FossilExpected | Select-Object -First 1
Write-Output "8. Found best slot at $($slot.Time)"

# Find all runbooks to schedule
$runbooks = Get-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName | Where-Object {$_.Tags.AutoSchedule -eq $true}
Write-Output "9. Found $($runbooks.count) runbooks to schedule in automation account $AutomationAccountName"

# Create a schedule
$schedule = New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name "GreenSchedule$($slot.Time.ToString("yyyyMMddhhmm"))" -StartTime $slot.Time -OneTime -ResourceGroupName $ResourceGroupName -TimeZone (([System.TimeZoneInfo]::Local).Id)
Write-Output "10. Schedule with name $($schedule.Name) created in automation account $AutomationAccountName"

# Link the runbooks to the schedule
$scheduled = ""
foreach($runbook in $runbooks){
    Register-AzAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -Name $runbook.Name -ScheduleName $schedule.Name -ResourceGroupName $ResourceGroupName
    $scheduled += $runbook.Name + ", "
}
Write-Output "11. The following runbooks where linked to schedule $($schedule.Name) : $($scheduled.Substring(0, $scheduled.Length-2))"