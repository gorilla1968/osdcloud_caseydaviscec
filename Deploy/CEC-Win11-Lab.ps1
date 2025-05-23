#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

# Define valid campus options
$validCampuses = @("A", "CR", "CSHS", "CSMS", "CS100", "FCHS", "FCMS", "DCN", "W", "O")

do {
    # Prompt for campus
    do {
        Write-Host "Enter campus code (Options: A, CR, CSHS, CSMS, CS100, FCHS, FCMS, DCN, W, O)" -ForegroundColor Cyan
        $campus = Read-Host
        $campus = $campus.ToUpper()
        $campusValid = $validCampuses -contains $campus
        if (-not $campusValid) {
            Write-Host "Invalid campus code. Please try again." -ForegroundColor Red
        }
    } until ($campusValid)

    # Prompt for room number
    do {
        Write-Host "Enter room number (100-500)" -ForegroundColor Cyan
        $roomNumber = Read-Host
        $roomValid = ($roomNumber -as [int]) -and ($roomNumber -ge 100) -and ($roomNumber -le 500)
        if (-not $roomValid) {
            Write-Host "Invalid room number. Please enter a number between 100 and 500." -ForegroundColor Red
        }
    } until ($roomValid)

    # Get the serial number of the machine
    $serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

    # Check if serial contains "To be filled by"
    if ($serial -match "To be filled by") {
        do {
            Write-Host "Serial number not set. Enter asset tag number (3-5 digits)" -ForegroundColor Cyan
            $assetTag = Read-Host
            $assetTagValid = $assetTag -match '^\d{3,5}$'
            if (-not $assetTagValid) {
                Write-Host "Invalid asset tag. Please enter a 3 to 5 digit number." -ForegroundColor Red
            }
        } until ($assetTagValid)
        $serial = $assetTag
    }

    # Construct the computer name
    $computerName = "CEC$campus-Lab$roomNumber-$serial"

    # Output the result
    Write-Host "Generated Computer Name: $computerName" -ForegroundColor Yellow

    # Ask for confirmation
    do {
        $confirmation = Read-Host "Is this correct? (y/n)"
    } until ($confirmation -match '^[yYnN]$')

} until ($confirmation -match '^[yY]$')

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "24H2"
    OSEdition = "Education"
    OSLanguage = "en-us"
    OSLicense = "Volume"
    ZTI = $true
    Firmware = $true
}
Start-OSDCloud @Params

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "AddNetFX3":  {
                      "IsPresent":  true
                  },
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                    "Microsoft.BingWeather",
                    "Microsoft.BingNews",
                    "Microsoft.GamingApp",
                    "Microsoft.GetHelp",
                    "Microsoft.Getstarted",
                    "Microsoft.Messaging",
                    "Microsoft.MicrosoftOfficeHub",
                    "Microsoft.MicrosoftSolitaireCollection",
                    "Microsoft.MicrosoftStickyNotes",
                    "Microsoft.MSPaint",
                    "Microsoft.People",
                    "Microsoft.PowerAutomateDesktop",
                    "Microsoft.StorePurchaseApp",
                    "Microsoft.Todos",
                    "microsoft.windowscommunicationsapps",
                    "Microsoft.WindowsFeedbackHub",
                    "Microsoft.WindowsMaps",
                    "Microsoft.WindowsSoundRecorder",
                    "Microsoft.Xbox.TCUI",
                    "Microsoft.XboxGameOverlay",
                    "Microsoft.XboxGamingOverlay",
                    "Microsoft.XboxIdentityProvider",
                    "Microsoft.XboxSpeechToTextOverlay",
                    "Microsoft.YourPhone",
                    "Microsoft.ZuneMusic",
                    "Microsoft.ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================


#================================================
#  [PostOS] OOBE CMD Command Line
#================================================
Invoke-RestMethod https://raw.githubusercontent.com/caseydaviscec/osdcloud/main/Set-LenovoAssetTag.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\set-lenovoassettag.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/caseydaviscec/osdcloud/refs/heads/main/Rename-LabComputer.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\rename-labcomputer.ps1' -Encoding ascii -Force


$OOBECMD = @'
@echo off

start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\set-lenovoassettag.ps1

# Below a PS session for debug and testing in system context, # when not needed 
# start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\rename-labcomputer.ps1
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
