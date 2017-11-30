$MDT_Server = "$(hostname)"

$Package_Share = "\\hlabs12st1\e$\USBDrive"
$MDT_Package = "E:\Windows Deployment\Microsoft\MDT\MDT2013Update2\MicrosoftDeploymentToolkit2013_x64.msi"
$ADK_Package = "E:\Windows Deployment\Microsoft\Windows Kits\10\ADK\adksetup.exe"

# Prepare for installation packages
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }
if (! (Test-Path $MDT_Package) -or ! (Test-Path $ADK_Package)) {
    Read-Host "Control Break, and make sure the all Software Packages are there!"
    }

$FeatureList = "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
Write-host "Windows Kit is going to be installed include the following features:-"
Write-host $FeatureList
Read-host "To capture and restore user profile, Ctrl+Break and add OptionId.UserStateMigrationTool to FeatureList"


# MDT install first
Start-Process -FilePath ${MDT_Package} -ArgumentList '/passive /norestart' -wait -PassThru

# AIK install ( For Windows7, Add-WindowsFeature -Name NET-Framework-Features first)
Start-Process -FilePath ${ADK_Package} -ArgumentList "/Features $FeatureList /ceip off /q /norestart" -Wait -PassThru

# Verification and Reboot
$(Get-WmiObject -Class Win32_Product).Name
Read-Host "Are MDT and ADK installed? Ctrl-C to troubleshoot, or any other key to reboot" 
Restart-Computer