$wifiProfilePath = "C:\Windows\Setup\scripts\Auenland_wifi.xml"
netsh wlan add profile filename="$wifiProfilePath" user=all
netsh wlan connect name="Auenland"
