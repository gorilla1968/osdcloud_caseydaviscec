# Transcript for logging
$stampDate = Get-Date
$scriptName = ([System.IO.Path]::GetFileNameWithoutExtension($(Split-Path $script:MyInvocation.MyCommand.Path -Leaf)))
$logFile = "$env:OSDCloud\Logs\$scriptName-" + $stampDate.ToFileTimeUtc() + ".log"
Start-Transcript -Path $logFile -NoClobber
$VerbosePreference = "Continue"

# Set Hostname before Autopilot
Write-Host -ForegroundColor Red "Rename Computer before Autopilot"
$computerName = Get-Content -Path "$env:SystemDrive\OSDCloud\Scripts\ComputerName.txt"
Rename-Computer -Newname $computerName -Restart

Stop-Transcript
