$downloadUrl = "https://gist.githubusercontent.com/gorilla1968/10501d125c2c558ce35c9162529c6a5f/raw/Auenland_wifi.xml"
$wifiProfilePath = "C:\Windows\Setup\scripts\Auenland_wifi.xml"

Invoke-WebRequest -Uri $downloadUrl -OutFile $wifiProfilePath

# Now use the rest of your script
netsh wlan add profile filename="$wifiProfilePath" user=all
[xml]$xmlContent = Get-Content $wifiProfilePath
$ssid = $xmlContent.WLANProfile.SSIDConfig.SSID.name
netsh wlan connect name="$ssid"
Start-Sleep -Seconds 5
$connectionStatus = netsh wlan show interfaces | Select-String "State"
Write-Host "Connection Status: $connectionStatus"
