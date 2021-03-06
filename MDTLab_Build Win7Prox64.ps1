﻿$MDT_Server = $(hostname)
$DS_Folder = "C:\DS1"
$DS_Name = "DS1"
$INI_Source = "C:\Users\da\Downloads\MDTlab"
$VM_Host = "S16GuiTest"

$Package_Share = "\\hlabs12st1\e$\USBDrive"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }

$ISO_Path = "C:\SW_DVD5_Win_Pro_7w_SP1_64BIT_English_-2_Upg_MLF_X17-59282.ISO" 
Write-Host "Making sure the Windows ISO file is inplace...."
if (! (Test-Path $ISO_Path)) { copy "E:\Windows\Win7\SW_DVD5_Win_Pro_7w_SP1_64BIT_English_-2_Upg_MLF_X17-59282.ISO" $ISO_Path }
$Build_Dest_Folder = "Windows 7 Pro SP1 x64"
$OS_folder = "W7x64"

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
Write-Host

# Create Appliation to install Big chunk of Windows updates right after install OS. 
$AppName = "Update – April 2015 servicing stack – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\April 2015 servicing stack"
$AppCmdline = "wusa.exe Windows6.1-KB3020369-x64.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}

$AppName = "Update –Convenience Roll Up (KB3125574) – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\Convenience Roll Up (KB3125574)"
$AppCmdline = "wusa.exe windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}

$AppName = "Update – 201711 Security Monthly Rollup (KB4048957) – Win7x64"
$AppSourcePath = "E:\Windows\ServicePack2_Windows 7 and Server 2008 R2 SP1 (KB976932)\2017-11 Security Monthly Quality for Windows 7 x64(KB4048957)"
$AppCmdline = "wusa.exe windows6.1-kb4048957-x64_83688ecf3a901fc494ee67b5c57e35f0a09dc455.msu /quiet /norestart" 
import-MDTApplication -path "DS001:\Applications\${OS_folder}" -enable "True" -Name ${AppName} -ShortName ${AppName} -Version "" -Publisher "" -Language "" -CommandLine ${AppCmdline} -WorkingDirectory ".\Applications\${AppName}" -ApplicationSourcePath ${AppSourcePath} -DestinationFolder ${AppName}
Write-Host
Write-Host "Maually add dependency of:-"
Write-host "        - application [Convenience Rollup] with application [April 2015 Servicing Stack]."
Write-host "        - application [201711 Security Monthly Rollup] with application [Convenience Rollup]."
Write-Host "Maually modify Task Sequence:[${BuildTS_Name}] to:-"
Write-Host "        - include application:[${AppName}] before the 1st [Windows Update], follow by a Reboot,"
Write-Host "        - Enable the 2nd [Windows Update], follow by a Reboot. "
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