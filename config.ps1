Write-Host  -ForegroundColor Cyan "Starting OSDCloud for Windows 11 24h2 sv-se"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host  -ForegroundColor Cyan "Updating OSDCloud PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Importing OSDCloud PowerShell Module"
Import-Module OSD -Force
Install-Script -Name Get-WindowsAutoPilotInfo -Force
Get-WindowsAutoPilotInfo -OutputFile "E:\HardwareHash.csv"

#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$OSVersion = 'Windows 11' #Used to Determine Driver Pack
$OSReleaseID = '22H2' #Used to Determine Driver Pack
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'sv-se'

#Used to Determine Driver Pack
$Product = (Get-MyComputerProduct)
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
Restart = [bool]$False
RecoveryPartition = [bool]$true
OEMActivation = [bool]$False
WindowsUpdate = [bool]$true
WindowsUpdateDrivers = [bool]$true
WindowsDefenderUpdate = [bool]$true
SetTimeZone = [bool]$True
ClearDiskConfirm = [bool]$False
}

if ($DriverPack){
$Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

#Enable HPIA | Update HP BIOS | Update HP TPM
if (Test-HPIASupport){
#$Global:MyOSDCloud.DevMode = [bool]$True
$Global:MyOSDCloud.HPTPMUpdate = [bool]$True
$Global:MyOSDCloud.HPIAALL = [bool]$true
$Global:MyOSDCloud.HPBIOSUpdate = [bool]$true
}

#write variables to console
$Global:MyOSDCloud

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

#Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
Write-Host  -ForegroundColor Cyan "Starting OSDCloud with Windows 11 24h2 sv-se"
Start-OSDCloud -OSVersion 'Windows 11' -OSLanguage sv-se -OSBuild 24H2 -OSEdition Enterprise -ZTI

# Extract-HardwareHash.ps1
$OutputFile = "E:\HardwareHash.csv"
$HardwareHash = Get-WindowsAutopilotInfo -OutputFile $OutputFile

# Append the hardware hash to the file
Add-Content -Path $OutputFile -Value $HardwareHash

# Run the script to extract hardware hash and append to file
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Extract-HardwareHash.ps1`""



#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
