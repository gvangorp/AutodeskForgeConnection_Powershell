#AppFolder is the writable temp folder to run the script with, for saving the login credentials and for downloading the file to. e.g. 'C:\TEMP\AutoRun\' 
$AppFolder = #Todo add AppFolder
#RedirectUrl can be like http://localhost:8000 - it needs to be added as a valid redirect url to https://forge.autodesk.com/myapps/
$RedirectUrl = #Todo add RedirectUrl
#ClientID can be retrieved from https://forge.autodesk.com/myapps/ after creating a new Forge App.
$ClientID = #Todo add ClientID
#ClientSecret can be retrieved from https://forge.autodesk.com/myapps/ after creating a new Forge App.
$ClientSecret = #Todo add ClientSecret
$LoginCredentials = @{AccessToken = $null; RefreshToken = $null; ExpirationSeconds = $null; }
$LoginCredentialsFile = 'LoginCredentials.log'
#AutodeskFileGuid is the file id to download.
$AutodeskFileGuid = #Todo add FileGuid

#region function helpers
#gettoken from https://forge.autodesk.com/en/docs/oauth/v1/reference/http/gettoken-POST/
Function GetAutodeskToken ([string]$clientId, [string]$clientSecret, [string]$code, [string]$redirectUri) {
    $result = Invoke-RestMethod https://developer.api.autodesk.com/authentication/v1/gettoken -Method Post -Body @{client_id = $clientId; client_secret = $clientSecret; grant_type = "authorization_code"; code = $code; redirect_uri = $redirectUri } -ContentType "application/x-www-form-urlencoded" -ErrorAction STOP
    if ($result.access_token) {
        $global:LoginCredentials.AccessToken = $result.access_token
        $global:LoginCredentials.RefreshToken = $result.refresh_token
        $global:LoginCredentials.ExpirationSeconds = [DateTimeOffset]::Now.ToUnixTimeSeconds() + $result.expires_in
        #saving login credentials to json in log file
        $global:LoginCredentials | ConvertTo-JSON | Set-Content -Path $LoginCredentialsFile
        Write-Output "Updated Access Token"
    }
    else {
        Write-Error "Read GetToken result failed: " $result.developerMessage
    }
}

#refreshtoken from https://forge.autodesk.com/en/docs/oauth/v1/reference/http/refreshtoken-POST/
Function RefreshAutodeskToken ([string]$clientId, [string]$clientSecret, [string]$refreshToken) {
    $result = Invoke-RestMethod https://developer.api.autodesk.com/authentication/v1/refreshtoken -Method Post -Body @{client_id = $clientId; client_secret = $clientSecret; grant_type = "refresh_token"; refresh_token = $refreshToken } -ContentType "application/x-www-form-urlencoded" -ErrorAction STOP
    if ($result.access_token) {
        $LoginCredentials.AccessToken = $result.access_token
        $LoginCredentials.RefreshToken = $result.refresh_token
        $LoginCredentials.ExpirationSeconds = [DateTimeOffset]::Now.ToUnixTimeSeconds() + $result.expires_in
        #updating login credentials to json in log file
        $global:LoginCredentials | ConvertTo-JSON | Set-Content -Path $LoginCredentialsFile
        Write-Output "Updated Access Token"
    }
    else {
        Write-Error "RefreshToken failed: $result"
    }
}
#endregion

#region main script
if (-Not(Test-Path -Path $AppFolder)) {
    mkdir -p $AppFolder
}
Set-Location $AppFolder
if (Test-Path -Path $LoginCredentialsFile) {
    #reading login credentials from json in log file
    $LoginCredentials = Get-Content -Path $LoginCredentialsFile -Raw | ConvertFrom-JSON
}
#setting current date to compate with access token validity; ExpirationSeconds
$currentDate = [DateTimeOffset]::Now.ToUnixTimeSeconds()

#if user has never logged in before
if ($null -eq $LoginCredentials.AccessToken) {
    #authorize from https://forge.autodesk.com/en/docs/oauth/v1/reference/http/authorize-GET/
    Write-Output "Open https://developer.api.autodesk.com/authentication/v1/authorize?response_type=code&client_id=$ClientID&redirect_uri=$RedirectUrl&scope=data:read and get the code from the returning url after the $RedirectUrl?code"
    $Code = Read-Host -Prompt 'Input the returning code'
    GetAutodeskToken $ClientID $ClientSecret $Code $RedirectUrl
}
elseif ($LoginCredentials.ExpirationSeconds -lt $currentDate) {
    #if access token is expired, refresh token
    Write-Output "Access Token Expired Refreshing now..."
    RefreshAutodeskToken $ClientID $ClientSecret $LoginCredentials.RefreshToken
}

#download the file
if (-Not($null -eq $LoginCredentials.AccessToken)) {
    $AccessToken = $LoginCredentials.AccessToken
    $webData = Invoke-RestMethod https://developer.api.autodesk.com/oss/v2/buckets/wip.dm.prod/objects/$($AutodeskFileGuid).rvt/signeds3download -Headers @{"Authorization" = "Bearer $AccessToken" }
    Invoke-WebRequest $webData.url -o "Q20.zip"
    & C:\Programme\7-Zip\7z.exe x -aoa -y C:\TEMP\AutoRun\Q20.zip -oC:\TEMP\AutoRun\Q20
    & 'C:\Program Files\Autodesk\Navisworks Manage 2021\FiletoolsTaskRunner.exe' /i "C:\TEMP\AutoRun\NWD_batsh.txt" /of "\\network\dfs\STR-PRJ\0518000_Q20 Neckarpark_Stuttgart\D_TA-Planung\Navisworks\Q20.nwd" /log "C:\TEMP\AutoRun\Q20_Log.log" /over /version 2019 /lang de-DE
}
#endregion