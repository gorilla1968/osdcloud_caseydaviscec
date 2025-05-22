# Install OSD Module
$module = Import-Module OSD -PassThru -ErrorAction Ignore
if (-not $module) {
    Write-Host "Installing OSD module"
    Install-Module OSD -Force | Out-Null
}
Import-Module OSD -Force | Out-Null

$OSDGatheringJSON = Get-OSDGather -Full | ConvertTo-Json

# Output OSDGathering JSON to a file
$JsonPath = "C:\OSDCloud\Logs\OSDCloud.json"
if (Test-Path $JsonPath){

    $JSON= Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
    $WinPECompleted = "$($JSON.TimeSpan.Minutes) minutes $($JSON.TimeSpan.Seconds) seconds"

    $OSDEnd = Get-Date
    $OSDCouldTime = New-TimeSpan -Start $JSON.TimeStart.DateTime -End $OSDEnd

    $OSDCouldTimeCompleted = "$($OSDCouldTime.Hours) hour(s) $($OSDCouldTime.Minutes) minutes $($OSDCouldTime.Seconds) seconds"
}

# Computer Variables
$ComputerName = $OSDGathering.OperatingSystem.CSName
$ComputerModel = $OSDGathering.ComputerSystemProduct.Name

$OS = $OSDGathering.OperatingSystem.Caption
$OSVersion = $OSDGathering.OperatingSystem.Version

$BiosSerialNumber = $OSDGathering.BIOS.SerialNumber
$BiosVersion = $OSDGathering.BIOS.SMBIOSBIOSVersion
$BiosReleaseDate = $OSDGathering.BIOS.ReleaseDate

$OSDCloudVersion = (Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()

$IPAddress = (Get-WmiObject win32_Networkadapterconfiguration | Where-Object{ $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1
$Connection = Get-NetAdapter -physical | Where-Object status -eq 'up'
$ConnectionName = $connection.Name
$ConnectionDescription = $connection.InterfaceDescription
$LinkSpeed = $connection.LinkSpeed
$SSIDset = (Get-NetConnectionProfile).Name

# Webhook URL for Microsoft Teams
$WebhookUrl = Get-Content -Path $env:SystemDrive\OSDCloud\Scripts\webhook.shh

# Create Adaptive Card payload
$AdaptiveCard = @{
    type = "message"
    attachments = @(
        @{
            contentType = "application/vnd.microsoft.card.adaptive"
            content = @{
                type = "AdaptiveCard"
                version = "1.4"
                body = @(
                    @{
                        type = "TextBlock"
                        text = "💻 Windows 11 Machine Deployed"
                        weight = "Bolder"
                        size = "Large"
                        color = "Good"
                    },
                    @{
                        type = "TextBlock"
                        text = "The following machine has been successfully deployed"
                        wrap = $true
                        size = "Medium"
                    },
                    @{
                        type = "FactSet"
                        facts = @(
                            @{
                                title = "Computer Name"
                                value = $ComputerName
                            },
                            @{
                                title = "OS Version"
                                value = $OSVersion
                            },
                            @{
                                title = "IP Address"
                                value = $IPAddress
                            },
                            @{
                                title = "Completed Imaging Time"
                                value = $OSDCouldTimeCompleted
                            }
                        )
                    }
                )
            }
        }
    )
}

# Convert payload to JSON
$Payload = $AdaptiveCard | ConvertTo-Json -Depth 10

# Post to Teams webhook
Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Payload -ContentType 'application/json'