#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$OSVersion = 'Windows 10' #Used to Determine Driver Pack
$OSReleaseID = '22H2' #Used to Determine Driver Pack
$OSName = 'Windows 10 22H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = 'en-us'

#Used to Determine Driver Pack
$Product = (Get-MyComputerProduct)
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
Restart = [bool]$False
RecoveryPartition = [bool]$true
OEMActivation = [bool]$True
WindowsUpdate = [bool]$true
WindowsUpdateDrivers = [bool]$true
WindowsDefenderUpdate = [bool]$true
SetTimeZone = [bool]$False
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

Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
