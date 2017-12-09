$MDT_Server = $(hostname)
$DS_Folder = "C:\DS1"
$DS_Name = "DS1"
$INI_Source = "C:\Users\da\Downloads\MDTlab"
$VM_Host = "S16GuiTest"

$Package_Share = "\\hlabs12st1\e$\USBDrive"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }

$ISO_Path = "C:\SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_-4_MLF_X19-82891.ISO"
Write-Host "Making sure the Windows ISO file is inplace...."
if (! (Test-Path $ISO_Path)) { Copy "E:\Windows\Server\2012\SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_-4_MLF_X19-82891.ISO" $ISO_Path }
$Build_Dest_Folder = "Windows Server 2012 R2 Std x64"
$OS_folder = "S12"

# Importing OS
Write-Host "Mounting the Windows ISO file and import the OS ...."
$MountVolume = Mount-DiskImage -ImagePath ${ISO_Path} -PassThru
$DriveLetter = ($MountVolume|Get-Volume).DriveLetter
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root ${DS_Folder}
import-mdtoperatingsystem -path "DS001:\Operating Systems\${OS_folder}" -SourcePath "${DriveLetter}:\" -DestinationFolder ${Build_Dest_Folder} -Verbose
Dismount-DiskImage -ImagePath ${ISO_Path}
Remove-Item -Path ${ISO_Path}

# ====== Creating Task sequences to Build Server 2012 Standard/datacenter x64 Refernce Image
Write-Host "Creating Task Sequences and Import Patches ...."
$BuildTS_Name = "Install Fresh Server 2012 DataCenter R2 x64 from DVD"
$BuildTS_ID = "BS12R2DCrx64"
Get-ChildItem DS001:\"Operating Systems\${OS_Folder}" | Where-Object {$_.name -like "*install*"} | fl
$OS_Path = "DS001:\Operating Systems\${OS_Folder}\Windows Server 2012 R2 SERVERDATACENTER in Windows Server 2012 R2 Std x64 install.wim"
Write-Host "The wim file part of '$OS_PATH' is from imported OS, same with above."
import-mdttasksequence -path "DS001:\Task Sequences\${OS_folder}" -Name $BuildTS_Name -Template "Client.xml" -Comments "" -ID $BuildTS_ID -Version "1.0" -OperatingSystemPath $OS_Path -FullName "User" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd" -Verbose

$BuildTS_Name = "Install Fresh Server 2012 Standard R2 x64 from DVD"
$BuildTS_ID = "BS12R2Stdx64"
Get-ChildItem DS001:\"Operating Systems\${OS_Folder}" | Where-Object {$_.name -like "*install*"} | fl
$OS_Path = "DS001:\Operating Systems\${OS_Folder}\Windows Server 2012 R2 SERVERSTANDARD in Windows Server 2012 R2 Std x64 install.wim"
Write-Host "The wim file part of '$OS_PATH' is from imported OS, same with above."
import-mdttasksequence -path "DS001:\Task Sequences\${OS_folder}" -Name $BuildTS_Name -Template "Client.xml" -Comments "" -ID $BuildTS_ID -Version "1.0" -OperatingSystemPath $OS_Path -FullName "User" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd" -Verbose


$CaptureTS_Name = "Sysprep and Capture an Server 2012 Standard R2 x644 installation" 
$CaptureTS_ID = "CS12R2x64"
import-mdttasksequence -path "DS001:\Task Sequences\${OS_Folder}" -Name ${CaptureTS_Name} -Template "CaptureOnly.xml" -Comments "" -ID ${CaptureTS_ID} -Version "1.0" -OperatingSystemPath ${OS_Path} -FullName "user" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd" -Verbose
Write-Host

# Create Appliation to install Big chunk of Windows updates right after install OS. 
$AppName = "Update – 2017-11 Security Monthly Rollup for 2012 R2 for x64(KB4048958) – Win10x64"
$AppSourcePath = "E:\Windows\W8+Srv2012 Updates\2017-11 Security Monthly Rollup for 2012 R2 for x64(KB4048958)"
$AppCmdline = "wusa.exe AMD64-all-windows8.1-kb4048958-x64_752378a781e1c600c37cf55245aeb47fd171a564.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName} -Verbose
Write-Host
Write-Host "Maually Modify ${BuildTS_Name} to include ${AppName},Reboot, before enabled "Windows Update", Reboot. "
Write-Host "Maually Modify ${BuildTS_Name} to include necessary Roles"
Read-Host "Follow above Instructions Press to continue..."

$Captured_WIM = ${BuildTS_ID} + "_" + $(get-date -f yyyyMMdd) + ".wim"

# Update Deployment Share, to be ready to build the image.
Get-Content $INI_Source\MDTLab_CustomSettings.ini.DS1 `
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
Write-Host "             - in PE tab, For x64 put ${INI_Source}\WinPE\x64 in Extra directory"
Read-Host "Click OK, wait for it to close up, and press any key to contiue here."
Write-Host "Updating Deployment Share..."
update-MDTDeploymentShare -path "DS001:"

Get-Content $INI_Source\MDTLab_CreateVM.template `
| % {$_ -replace "<MyMDT_Svr>","${MDT_Server}"} `
| % {$_ -replace "<MyMDT_DS>","${DS_Name}"} `
| % {$_ -replace "<MyVM_Name>","${BuildTS_ID}"} `
| Out-File -Encoding ascii ${INI_Source}\MDTLab_CreateVM.ps1
Invoke-Command -ComputerName $VM_Host -FilePath ${INI_Source}\MDTLab_CreateVM.ps1
Write-Host 
Write-Host "Check your Hyper-V host:[$VM_Host] for VM: [$BuildTS_ID], wait for it to be shutdown."
Write-Host "then verify $DS_Folder\Captures folder for ${Captured_WIM}."
Write-Host "It might takes a few hours."
