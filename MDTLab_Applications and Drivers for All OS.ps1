$MDT_Server = "$(hostname)"
$DS_Folder = "C:\DS2"
$PSDriveName = "DS002"

$Package_Share = "\\S12GuiMDT\e$"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "${PSDriveName}" -PSProvider "MDTProvider" -Root "${DS_Folder}"

# Only for testing purpose, create a postOS TS, and manually run Script\BDD_Autorun.wsf to confirm what ever included in it. 
$TSName = "PostDeploy - Modify me to TEST Apps without Reboot" 
$TSID = "P-TestApps-001"
import-mdttasksequence -Path "${PSDriveName}:\Task Sequences" -Name ${TSName} -Template "StateRestore.xml" -Comments "" -ID ${TSID} -Version "1.0" -Verbose
Write-Host "Maually Modify ${TSID} to include of newly ceated Application, then run Script\BDD_Autorun.wsf to test/verify it without reboot"

# TS for the first step of replacing a comptuer with captured user data
$TSName = "PreReplace - Backup User Data Computer to be replaced" 
$TSID = "R-BackUp-001"
import-mdttasksequence -path "${PSDriveName}:\Task Sequences" -Name ${TSName} -Template "ClientReplace.xml" -Comments "" -ID ${TSID} -Version "1.0" -Verbose


# ===============================================
# For HP computers, create the SSM application. 
import-MDTApplication `
-path "${PSDriveName}:\Applications\HP" `
-enable "True" `
-Name "Drivers - HP SSM v1" `
-ShortName "Drivers - HP SSM v1" `
-Version "" -Publisher "" -Language "" `
-CommandLine "\\S12GuiMDT\HP\ssm.exe \\S12GuiMDT\HP /accept /install /noreboot" `
-WorkingDirectory ".\Applications\" `
-NoSource -Verbose

# ===============================================
# For My HP EliteBook 8560w, missing NIC driver for Win7x64. Found it from SP60775 easily.
import-mdtdriver `
-path "${PSDriveName}:\Out-of-Box Drivers\W7x64" `
-SourcePath "E:\LABs\Flat\WIN7-x64" `
-Verbose
Write-host "This driver is for Windows 8 only, but Windows 8 Image has it included. If not, import it again for consistenace"
Read-host "Include Out-of-Box Drivers\W7x64 in Windows 7 Deployment TS, press to continue"

# From SP55282 - for NIC driver of WinPE - VEN number actually found int b57nd60a, but a later version of driver was already imported. 
# I double this will work, but let's see....
# import-mdtdriver -path "${PSDriveName}:\Out-of-Box Drivers\WinPE10x64" -SourcePath "E:\SWSetup\SP55282\Vista_Win7\x64" -Verbose
# Creating new item named Broadcom Net b57nd60a.inf 15.0.0.17 at ${PSDriveName}:\Out-of-Box Drivers\WinPE10x64.
# Creating new item named Broadcom Net k57nd60a.inf 15.0.0.6 at ${PSDriveName}:\Out-of-Box Drivers\WinPE10x64.





# ===============================================
# .NET frame work for All Windows except Win10 and Srv 2016?

import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Install – Microsoft .NET Framework 4.5.2" `
-ShortName "Install – Microsoft .NET Framework 4.5.2" `
-Version "" -Publisher "" -Language "" `
-CommandLine "cscript.exe Install-NetFramework452.wsf" `
-WorkingDirectory ".\Applications\Install – Microsoft .NET Framework 4.5.2" `
-ApplicationSourcePath "E:\Windows Add-Ons\Microsoft .NET Frameworks for allOSs\4.5.2" `
-DestinationFolder "Install – Microsoft .NET Framework 4.5.2" `
-Verbose

import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Install – Microsoft .NET Framework 4.6.2" `
-ShortName "Install – Microsoft .NET Framework 4.6.2" `
-Version "" -Publisher "" -Language "" `
-CommandLine "cscript.exe Install-NetFramework462.wsf" `
-WorkingDirectory ".\Applications\Install – Microsoft .NET Framework 4.6.2" `
-ApplicationSourcePath "E:\Windows Add-Ons\Microsoft .NET Frameworks for allOSs\4.6.2" `
-DestinationFolder "Install – Microsoft .NET Framework 4.6.2" `
-Verbose

import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Install – Microsoft .NET Framework 4.7" `
-ShortName "Install – Microsoft .NET Framework 4.7" `
-Version "" -Publisher "" -Language "" `
-CommandLine "cscript.exe Install-NetFramework47.wsf" `
-WorkingDirectory ".\Applications\Install – Microsoft .NET Framework 4.7" `
-ApplicationSourcePath "E:\Windows Add-Ons\Microsoft .NET Frameworks for allOSs\4.7" `
-DestinationFolder "Install – Microsoft .NET Framework 4.7" `
-Verbose
Read-Host "To decrease the time needed for windows update, modify building TS to install it first. Press to continue..."



# ===============================================
# Chrome Enterpise for All Windows 

import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Install – Chrome Enterprise x64 – allOSs" `
-ShortName "Install – Chrome Enterprise x64 – allOSs" `
-Version "" -Publisher "" -Language "" `
-CommandLine "msiexec /i googlechromestandaloneenterprise64.msi /passive" `
-WorkingDirectory ".\Applications\Install – Chrome Enterprise x64 – allOSs" `
-ApplicationSourcePath "E:\Windows Add-Ons\Chrome Enterprise x64" `
-DestinationFolder "Install – Chrome Enterprise x64 – allOSs" `
-Verbose

# ===============================================
# FireFox ESR for All Windows 
# Only the firefox exe file is required for now on
import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Install – FireFox v52.3.0sr x64 – allOSs" `
-ShortName "Install – FireFox v52.3.0sr x64 – allOSs" `
-Version "" -Publisher "" -Language "" `
-CommandLine "Firefox Setup 52.3.0esr.exe -ms" `
-WorkingDirectory ".\Applications\Install – FireFox v52.3.0sr x64 – allOSs" `
-ApplicationSourcePath "E:\Windows Add-Ons\FireFox x64 v52.3.0sr" `
-DestinationFolder "Install – FireFox v52.3.0sr x64 – allOSs" `
-Verbose


# ===============================================
# Clean up before Sysprep for All Windows
import-MDTApplication `
-Path "${PSDriveName}:\Applications\allOSs" `
-enable "True" `
-Name "Action – Cleanup Before Sysprep" `
-ShortName "Action – Cleanup Before Sysprep" `
-Version "" -Publisher "" -Language "" `
-CommandLine "cscript.exe Action-CleanupBeforeSysprep.wsf" `
-WorkingDirectory ".\Applications\Action – Cleanup Before Sysprep" `
-ApplicationSourcePath "E:\Windows Add-Ons\Action – Cleanup Before Sysprep" `
-DestinationFolder "Action – Cleanup Before Sysprep" `
-Verbose
Read-Host "Add this Cleanup appliation to all Build and Capture TS in the Custom folder. Press to continue..."

# ===============================================
# PowerShell 5.1 for Windows 7 and 2008
import-MDTApplication `
-Path "${PSDriveName}:\Applications\W7x64" `
-enable "True" `
-Name "Install – PowerShell 5.1 -W7(2008)x64" `
-ShortName "Install – PowerShell 5.1 -W7(2008)x64" `
-Version "" -Publisher "" -Language "" `
-CommandLine "wusa.exe Win7AndW2K8R2-KB3191566-x64.msu /quiet /norestart" `
-WorkingDirectory ".\Applications\Install – PowerShell 5.1 -W7(2008)x64" `
-ApplicationSourcePath "E:\Windows Add-Ons\Windows Management Framework (WMF) 5.1\Win7(2008)x64" `
-DestinationFolder "Install – PowerShell 5.1 -W7(2008)x64" `
-Verbose
Read-Host "Modify this Application to depend on .NET framework 4.5.1 or later"

# PowerShell 5.1 for Windows 8.1 and 2012R2 x64
import-MDTApplication `
-Path "${PSDriveName}:\Applications\S12" `
-enable "True" `
-Name "Install – PowerShell 5.1 -W81(2012R2)x64" `
-ShortName "Install – PowerShell 5.1 -W81(2012R2)x64" `
-Version "" -Publisher "" -Language "" `
-CommandLine "wusa.exe Win8.1AndW2K12R2-KB3191564-x64.msu /quiet /norestart" `
-WorkingDirectory ".\Applications\Install – PowerShell 5.1 -W81(2012R2)x64" `
-ApplicationSourcePath "E:\Windows Add-Ons\Windows Management Framework (WMF) 5.1\Win81(2012R2)x64" `
-DestinationFolder "Install – PowerShell 5.1 -W81(2012R2)x64" `
-Verbose
Read-Host "Modify this Application to depend on .NET framework 4.5.1 or later. However, it will install .NET again if it's already included."
