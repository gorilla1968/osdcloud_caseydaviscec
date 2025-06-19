# Define variables
$requiredModuleVersion = "25.6.10.1"
$isoFileName = "CECWin11.1.2.iso"
$isoDownloadUrl = "http://cec-mdt.cec.coloradoearlycolleges.org/CECWin11.1.2.iso"
$isoLocalPath = Join-Path -Path $env:TEMP -ChildPath $isoFileName

# Step 1: Install specific version of OSD module if not already installed
if (-not (Get-Module -ListAvailable -Name OSD | Where-Object Version -eq $requiredModuleVersion)) {
    Write-Host "Installing OSD module version $requiredModuleVersion..."
    Install-Module -Name OSD -RequiredVersion $requiredModuleVersion -Force -Scope CurrentUser
}

# Step 2: Import OSD module
Import-Module OSD -Version $requiredModuleVersion -Force

# Step 3: Download newest ISO file
Write-Host "Downloading ISO from $isoDownloadUrl..."
try{
    Invoke-WebRequest -Uri $isoDownloadUrl -OutFile $isoLocalPath
}
catch {
    Write-Host "Error downloading ISO."
    Write-Host "Are you connected to the internet at a CEC school or VPN?"
    Write-Host "Please check your connection and try again."
    exit 1
}
# Step 4: Create OSDCloud USB from downloaded ISO
Write-Host "Creating OSDCloud USB from local ISO..."
New-OSDCloudUSB -fromIsoFile $isoLocalPath

# Step 5: Delete downloaded ISO
Write-Host "Deleting temporary ISO..."
Remove-Item $isoLocalPath -Force

# Step 6: Update USB with specified OS settings
Write-Host "Updating OSDCloud USB with Windows 11 24H2 Volume License ISO..."
Update-OSDCloudUSB -OSName 'Windows 11 24H2' -OSLanguage en-us -OSActivation Volume

Write-Host "✅ OSDCloud USB process completed successfully."
