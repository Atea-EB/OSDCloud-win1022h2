Write-Host  -ForegroundColor Cyan "Starting OSDCloud for Windows 10 22h2 sv-se"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host  -ForegroundColor Cyan "Updating OSDCloud PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Importing OSDCloud PowerShell Module"
Import-Module OSD -Force


#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$OSVersion = 'Windows 10' #Used to Determine Driver Pack
$OSReleaseID = '22H2' #Used to Determine Driver Pack
$OSName = 'Windows 10 22H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'sv-se'

#Used to Determine Driver Pack
$Product = (Get-MyComputerProduct)
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
AutopilotJsonChildItem = $null
AutopilotJsonItem = $null
AutopilotJsonName = $null
AutopilotJsonObject = $null
AutopilotJsonString = $null
AutopilotJsonUrl = $null
AutopilotOOBEJsonChildItem = $null
AutopilotOOBEJsonItem = $null
AutopilotOOBEJsonName = $null
AutopilotOOBEJsonObject = $null
OOBEDeployJsonChildItem = $null
OOBEDeployJsonItem = $null
OOBEDeployJsonName = $null
OOBEDeployJsonObject = $null
OSLicense = $null
TSAutopilotConfig = $null
TSProvisioning = $null
TSScriptStartup = $null
TSScriptShutdown = $null
Restart = [bool]$false
RecoveryPartition = [bool]$true
OEMActivation = [bool]$false
WindowsUpdate = [bool]$true
WindowsUpdateDrivers = [bool]$true
WindowsDefenderUpdate = [bool]$true
SetTimeZone = [bool]$True
ClearDiskConfirm = [bool]$false
SkipAllDiskSteps = [bool]$false
SkipAutopilot = [bool]$false
SkipAutopilotOOBE = [bool]$false
SkipClearDisk = [bool]$false
SkipODT = [bool]$false
SkipOOBEDeploy = [bool]$false
SkipNewOSDisk = [bool]$false
SkipRecoveryPartition = [bool]$false
BuildName = 'OSDCloud'
ZTI = [bool]$true
}

if ($DriverPack){
$Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

#Enable HPIA | Update HP BIOS | Update HP TPM
#if (Test-HPIASupport){
#$Global:MyOSDCloud.DevMode = [bool]$True
#$Global:MyOSDCloud.HPTPMUpdate = [bool]$True
#$Global:MyOSDCloud.HPIAALL = [bool]$true
#$Global:MyOSDCloud.HPBIOSUpdate = [bool]$true
#}

#write variables to console
$Global:MyOSDCloud

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

#Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
Write-Host  -ForegroundColor Cyan "Starting OSDCloud with Windows 11 24h2 sv-se"
Start-OSDCloud -OSVersion 'Windows 10' -OSLanguage sv-se -OSBuild 22H2 -OSEdition Enterprise 
#-ZTI

#Hardware Hash



#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
