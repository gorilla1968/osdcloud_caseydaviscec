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
$prefix = "CEC"
$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
$ComputerName = "$prefix-$serialNumber"
$IPAddress = (Get-WmiObject win32_Networkadapterconfiguration | Where-Object{ $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1
$Connection = Get-NetAdapter -physical | Where-Object status -eq 'up'

# Fetch the webhook URL from Azure Key Vault
Install-Module Az.Accounts -Force
Install-Module Az.KeyVault -Force

Import-Module Az.Accounts
Import-Module Az.KeyVault

$ApplicationId = "d0f55dbf-e2ec-4020-bc22-f299c06a737a"
$SecuredPassword = Get-Content -Path $env:SystemDrive\CECWin11\Config\Scripts\osdcloud.shh
$tenantID = "756e5b19-b4c4-4dc1-ae63-693179768af4"

$SecuredPasswordPassword = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPasswordPassword

$keyVaultName = "cecwin11"
$secretName = "WEBHOOK"

# Connect to Azure account
Connect-AzAccount -ServicePrincipal -Credential $ClientSecretCredential -Tenant $TenantID 

# Retrieve the secret from Azure Key Vault
$webhook = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -AsPlainText -Verbose

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
                        text = "Windows 11 Machine Deployed"
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
Invoke-RestMethod -Uri $webhook -Method Post -Body $Payload -ContentType 'application/json'
