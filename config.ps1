Write-Host  -ForegroundColor Cyan "Starting OSDCloud for Windows 11 24h2 sv-se"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host  -ForegroundColor Cyan "Updating OSDCloud PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Importing OSDCloud PowerShell Module"
Import-Module OSD -Force


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

#Hardware Hash


function Get-HardwareHash
 {
    $hardwareHash = ""  
    $deviceDetail = (Get-WMIObject -ComputerName @($env:ComputerName) -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
 
    if($deviceDetail) {
        $hardwareHash = $deviceDetail.DeviceHardwareData
    }
    else {
        throw "Failed to retrive hardware hash."
    }

    return $hardwareHash
}

function Get-SerialNumber 
{
    $serialNumber = ""
    $deviceBios = (Get-WmiObject -ComputerName @($env:ComputerName) -Class Win32_BIOS)

    if($deviceBios) {
        $serialNumber = $deviceBios.SerialNumber
    }
    else {
        throw "Failed to retrive serial number."
    }

    return $serialNumber
}

function Get-ManufacturerName 
{
    $manufacturerName = "";
    $deviceComputerSystem = (Get-WmiObject -ComputerName @($env:ComputerName) -Class Win32_ComputerSystem)

    if($deviceComputerSystem) {
        $manufacturerName = $deviceComputerSystem.Manufacturer
    }
    else {
        throw "Failed to retrive manufacturer"
    }

    return $manufacturerName
}

function Get-AEPManufacturerIdForWap
{
    $manufacturerId = 0; 
    $manufacturers = @(
        [PSCustomObject]@{Name = "Acer"; Id = 27},
        [PSCustomObject]@{Name = "Dell"; Id = 28},
        [PSCustomObject]@{Name = "HP"; Id = 29},
        [PSCustomObject]@{Name = "Lenovo"; Id = 30},
        [PSCustomObject]@{Name = "Microsoft Corporation"; Id = 31},
        [PSCustomObject]@{Name = "Asus"; Id = 32},
        [PSCustomObject]@{Name = "Dynabook"; Id = 33},
        [PSCustomObject]@{Name = "Fujitsu"; Id = 34},
        [PSCustomObject]@{Name = "Getac"; Id = 35},
        [PSCustomObject]@{Name = "Panasonic"; Id = 36},
        [PSCustomObject]@{Name = "Samsung"; Id = 51}
    )

    try {
        $localManufacturerName = Get-ManufacturerName    
    }
    catch {
        throw $PSItem
    }

    foreach($manufacturer in $manufacturers) 
    {
        if($localManufacturerName -eq $manufacturer.Name) {
            $manufacturerId = $manufacturer.Id
        }
    }

    if($manufacturerId -eq 0) {
        throw "Failed to find manufacturer id"
    }

    return $manufacturerId
}

function Get-JTConnectionString
{
    # Read credentials from CSV. 
    $credentials = Import-Csv $PSScriptRoot"\JT-Credentials.csv"

    Write-Host $credentials.server

    $connectionString = "server=$($credentials.server);database=$($credentials.database);user id=$($credentials.user);password=$($credentials.password)"

    return $connectionString
}

function Save-HardwareHashInJT
{
    $serialNumber = Get-SerialNumber
    $hardwareHash = Get-HardwareHash

    # Prepare connection. 
    $connectionString = Get-JTConnectionString
    $sqlConnection = New-Object System.Data.SQLClient.SQLConnection($connectionString)

    # Define call to procedure. 
    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand   
    $sqlCommand.Connection = $sqlConnection 
    $sqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure
    $sqlCommand.CommandText = "JT2000.dbo.JT_AddSerialHash"
    $sqlCommand.CommandTimeout = 120

    # Define input/output parameters. 
    $sqlCommand.Parameters.Add("@serial", [System.Data.SqlDbType]::varchar) | out-Null
    $sqlCommand.Parameters['@serial'].Direction = [System.Data.ParameterDirection]::Input
    $sqlCommand.Parameters['@serial'].value = $serialNumber
    $sqlCommand.Parameters.Add("@hash", [System.Data.SqlDbType]::varchar) | out-Null
    $sqlCommand.Parameters['@hash'].Direction = [System.Data.ParameterDirection]::Input
    $sqlCommand.Parameters['@hash'].value = $hardwareHash
    $sqlCommand.Parameters.Add("@returncode", [System.Data.SqlDbType]::int) | out-Null
    $sqlCommand.Parameters['@returncode'].Direction = [System.Data.ParameterDirection]::Output
    $sqlCommand.Parameters['@returncode'].value = -1

    # Open connection and inject into db. 
    Try {
        $sqlConnection.Open()
        $sqlCommand.ExecuteNonQuery() | out-null
        $sqlConnection.Close()
    }
    Catch {
        throw $PSItem
    }
}

function Save-ToIntuneCsv ($append = $false)
{
    $serialNumber = Get-SerialNumber
    $hardwareHash = Get-HardwareHash

    $deviceProperties = [ordered] @{
        "Device Serial Number" = $serialNumber
        "Windows Product ID" = ""
        "Hardware Hash" = $hardwareHash
        "Manufacturer name" = ""
        "Device model" = ""
    }

    $device = New-Object psObject -Property $deviceProperties

    try {
        if($append) {
            $devices = @()
    
            $devices += $device
            $devices += Import-Csv $PSScriptRoot"\devices.csv"
            $devices | ConvertTo-Csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File -FilePath $PSScriptRoot"\devices.csv"
        }
        else {
            $device | ConvertTo-Csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File -FilePath $PSScriptRoot"\devices.csv"
        }
    }
    catch {
        throw "Failed to save to devices.csv"
    }
}

function Save-ToAEPCsv ($append = $false)
{
    $device = [PSCustomObject]@{
        Serial = ""
        UnusedOne = ""
        Manufacturer = ""
        ModelName = ""
        DeviceId = ""
        UnusedTwo = ""
        HardwareHash = ""
    }

    try {
        $device.Serial = Get-SerialNumber
        $device.HardwareHash = Get-HardwareHash
        $device.Manufacturer = Get-AEPManufacturerIdForWap
    }
    catch {
        throw $PSItem
    }

    try {
        if($append) {
            $devices = @()
    
            $devices += $device
            $devices += Import-Csv $PSScriptRoot"\devices.csv"
            $devices | ConvertTo-Csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File -FilePath $PSScriptRoot"\devices.csv"
        }
        else {
            $device | ConvertTo-Csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File -FilePath $PSScriptRoot"\devices.csv"
        }
    }
    catch {
        throw "Failed to save to devices.csv"
    }
}

try {
    $OutputPath = "D:\devices.csv"
    Save-ToIntuneCsv -Path $OutputPath .\MSAP
    Write-Host "Saved: $(Get-SerialNumber) to $OutputPath"
}
catch {
    Write-Host $PSItem.ToString()
}


Write-Host "Press any key to continue.."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")








#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
