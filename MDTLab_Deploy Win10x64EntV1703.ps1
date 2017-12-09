$MDT_Server = $(hostname)
$DS_Folder = "C:\DS2"
$DS_Name = "DS2"
$INI_Source = "C:\Users\da\Downloads\MDTlab"
$WDS_Server = "HLABS16CTX"

$Package_Share = "\\hlabs12st1\e$\USBDrive"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }

$Image_Share = "\\DESKTOP-F311JPG\DS1$\Captures"
$BuildTS_ID = "BW10Ent1703x64"
$Captured_WIM = "BW10Ent1703x64_20171208.wim" 
Write-Host "Making sure the Captured Windows WIm file is inplace...."
if (! (Test-Path C:\${Captured_WIM})) { copy "${Image_Share}\${Captured_WIM}" C:\${Captured_WIM} }
$Deploy_Dest_Folder = "Captured Win10 Ent v1703 x64"
$OS_folder = "W10x64"

# Import the Captures Image done above
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root ${DS_Folder}
import-mdtoperatingsystem -path "DS002:\Operating Systems\${OS_folder}" -SourceFile "C:\${Captured_WIM}" -DestinationFolder ${Deploy_Dest_Folder} -Move -Verbose

Get-ChildItem DS002:\"Operating Systems\${OS_Folder}" | Where-Object {$_.name -like "*${Captured_WIM}*"} | fl

Read-Host "Name : ${BuildTS_ID}DDrive in ${Deploy_Dest_Folder} ${Captured_WIM}"  - Is this same above? Control Break if they are not
$REF_Path = "DS002:\Operating Systems\${OS_Folder}\${BuildTS_ID}DDrive in ${Deploy_Dest_Folder} ${Captured_WIM}"

# Create Task Sequence to deploy the Captured Image done above
$DeployTS_Name = "Deploy Win10 Ent v1703 x64 from Captured WIM file"
$DeployTS_ID = "DW10Ent1703x64"
import-mdttasksequence -path "DS002:\Task Sequences\${OS_folder}" -Name ${DeployTS_Name} -Template "Client.xml" -Comments "" -ID ${DeployTS_ID} -Version "1.0" -OperatingSystemPath ${REF_Path} -FullName "User" -OrgName "Home" -HomePage "about:blank" -AdminPassword "p@ssw0rd"
# Create Task Sequence to deploy the Captured Image to VHD file
$DeployTS_Name = "Deploy Win10 Ent v1703 x64 to VHD file from Captured WIM file"
$DeployTS_ID = "DvW10Ent1703x64"
import-mdttasksequence -path "DS002:\Task Sequences\${OS_Folder}" -Name ${DeployTS_Name} -Template "VHDClient.xml" -Comments "" -ID ${DeployTS_ID} -Version "1.0" -OperatingSystemPath ${REF_Path} -FullName "user" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd"
# Creating Task sequence to Capture image
$CaptureTS_Name = "Sysprep and Capture an Win10 Ent v1703 x64 installation" 
$CaptureTS_ID = "CW10Ent1703x64"
import-mdttasksequence -path "DS002:\Task Sequences\${OS_folder}" -Name ${CaptureTS_Name} -Template "CaptureOnly.xml" -Comments "" -ID $CaptureTS_ID -Version "1.0" -OperatingSystemPath $REF_Path -FullName "user" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd"

# Update Deployment Share, to be ready to build the image.
Get-Content $INI_Source\MDTLab_CustomSettings.ini.DS2 `
| % {$_ -replace "<MyCaptured_WIMfile>","$Captured_WIM"} `
| % {$_ -replace "<MyBuilding_TSID>","$BuildTS_ID"} `
| % {$_ -replace "<MyMDT_Svr>","$MDT_Server"} `
| Out-File -Encoding ascii ${DS_Folder}\Control\CustomSettings.ini
Get-Content $INI_Source\MDTLab_Bootstrap.ini.DS `
| % {$_ -replace "<MyMDT_Svr>","${MDT_Server}"} `
| % {$_ -replace "<MyMDT_DS>","${DS_Name}"} `
| Out-File -Encoding ascii ${DS_Folder}\Control\Bootstrap.ini
Write-Host "Maually right click the Deployment Share, and "
Write-Host "             - in General tab, uncheck x86, click Apply."
Write-Host "             - in Monitoring tab, check Enable Monitoring, click Apply."
Write-Host "             - in PE tab, For x64 put ${INI_Source}\x64 in Extra directory"
Read-Host "Click OK, wait for it to close up, and press any key to contiue here."
Write-Host "Updating Deployment Share..."
update-MDTDeploymentShare -path "DS002:"

Get-Content $INI_Source\MDTLab_ImportBootImagesOnWDS.template `
| % {$_ -replace "<MyMDT_Svr>","${MDT_Server}"} `
| % {$_ -replace "<MyMDT_DS>","${DS_Name}"} `
| Out-File -Encoding ascii ${INI_Source}\MDTLab_ImportBootImagesOnWDS.ps1

Write-Host "Logon to $WDS_Server and run this modified MDTLab_ImportBootImagesOnWDS.ps1 with elevated permission"
Invoke-Command -ComputerName $WDS_Server -FilePath ${INI_Source}\MDTLab_ImportBootImagesOnWDS.ps1