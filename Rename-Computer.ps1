#Start the Transcript
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

# Setting the hostname
Write-Host -ForegroundColor Red "Rename Computer before Autopilot"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
Rename-Computer -Newname CEC-$AssignedComputerName -Force
Restart-Computer -Force
