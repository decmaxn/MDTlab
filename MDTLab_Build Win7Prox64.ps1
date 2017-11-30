$MDT_Server = $(hostname)
$DS_Folder = "C:\DS1"
$DS_Name = "DS1"
$INI_Source = "C:\Users\da\Downloads\MDTlab"

$Package_Share = "\\hlabs12st1\e$\USBDrive"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }

$ISO_Path = "C:\SW_DVD5_Win_Pro_7w_SP1_64BIT_English_-2_Upg_MLF_X17-59282.ISO" 
Write-Host "Making sure the Windows ISO file is inplace...."
if (! (Test-Path $ISO_Path)) { copy "E:\Windows\Win7\SW_DVD5_Win_Pro_7w_SP1_64BIT_English_-2_Upg_MLF_X17-59282.ISO" $ISO_Path }
$Build_Dest_Folder = "Windows 7 Pro SP1 x64"
$OS_folder = "W7X64"

# Importing OS
Write-Host "Mounting the Windows ISO file and import the OS ...."
$MountVolume = Mount-DiskImage -ImagePath ${ISO_Path} -PassThru
$DriveLetter = ($MountVolume|Get-Volume).DriveLetter
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root ${DS_Folder}
import-mdtoperatingsystem -path "DS001:\Operating Systems\${OS_folder}" -SourcePath "${DriveLetter}:\" -DestinationFolder ${Build_Dest_Folder}
Dismount-DiskImage -ImagePath ${ISO_Path}
Remove-Item -Path ${ISO_Path}

# Creating OS Building and/or Capture Task sequences
Write-Host "Creating Task Sequences and Import Patches ...."
$BuildTS_Name = "Install Fresh Win7 Pro x64 from DVD"
$BuildTS_ID = "BW7Px64"
Get-ChildItem DS001:\"Operating Systems\${OS_Folder}" | Where-Object {$_.name -like "*install*"} | fl
$OS_Path = "DS001:\Operating Systems\${OS_Folder}\Windows 7 PROFESSIONAL in Windows 7 Pro SP1 x64 install.wim"
Write-Host "The wim file part of '$OS_PATH' is from imported OS, same with above."
import-mdttasksequence -path "DS001:\Task Sequences\${OS_folder}" -Name $BuildTS_Name -Template "Client.xml" -Comments "" -ID $BuildTS_ID -Version "1.0" -OperatingSystemPath $OS_Path -FullName "User" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd"

$CaptureTS_Name = "Sysprep and Capture an Windows 7 Pro x64 installation" 
$CaptureTS_ID = "CW7Px64"
import-mdttasksequence -path "DS001:\Task Sequences\${OS_folder}" -Name ${CaptureTS_Name} -Template "CaptureOnly.xml" -Comments "" -ID $CaptureTS_ID -Version "1.0" -OperatingSystemPath $OS_Path -FullName "user" -OrgName "LAB" -HomePage "about:blank" -AdminPassword "p@ssw0rd"

# Create Appliation to install Big chunk of Windows updates right after install OS. 
$AppName = "Update – April 2015 servicing stack – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\April 2015 servicing stack"
$AppCmdline = "wusa.exe Windows6.1-KB3020369-x64.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}

$AppName = "Update –Convenience Roll Up (KB3125574) – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\Convenience Roll Up (KB3125574)"
$AppCmdline = "wusa.exe windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}
Write-Host "Maually add dependency of Convenience Rollup with April 2015 Servicing Stack. Press to continue..."
Read-Host "Follow above comments. Press to continue..."

$AppName = "Update – 201708 Security Monthly Rollup (KB4034664) – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\2017-08 Security Monthly Rollup for Windows 7 x64(KB4034664)"
$AppCmdline = "wusa.exe windows6.1-kb4034664-x64_e4daa48a7407d5921d004dd550d62d91bf25839e.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}
Write-Host "Maually add dependency of 201708 Security Monthly Rollup with Convenience Rollup. Press to continue..."
Write-Host "Maually Modify ${BuildTS_Name} to include ${AppName},Reboot, before enabled "Windows Update", Reboot. "
Read-Host "Follow above Instructions. Press to continue..."

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
update-MDTDeploymentShare -path "DS001:"

$VM_Host = "S16GuiTest"
Read-Host "Modify MDTLab_CreateVM.ps1 to creat/boot VM:$BuildTS_ID, it will automatically deploy above OS, Capture to ${Captured_WIM}."
Read-Host "Press if the Hyper-V host is $VM_Host..."
Invoke-Command -ComputerName $VM_Host -FilePath ${INI_Source}\MDTLab_CreateVM.ps1
