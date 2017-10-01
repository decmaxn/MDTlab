$MDT_Server = $(hostname)
$DS_Folder = "C:\DS2"
$DS_Name = "DS2"
$DS_Desc = "MDT Deployer"
$BuilderAccount = "du"

New-Item -Path "${DS_Folder}" -ItemType directory
# Creat the deployment share
New-SmbShare -Name "${DS_Name}$" -Path "${DS_Folder}" -FullAccess Administrators -ChangeAccess $BuilderAccount
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "${DS_Folder}" -Description ${DS_Desc} -NetworkPath "\\${MDT_Server}\${DS_Name}$"  | add-MDTPersistentDrive 
icacls.exe ${DS_Folder}\Captures /grant "${BuilderAccount}:(OI)(CI)(M)"

# Prepare for central Log folder
new-item -Path ${DS_Folder}\Logs -ItemType Directory
icacls.exe ${DS_Folder}\Logs /grant ""${BuilderAccount}":(OI)(CI)(M)"

# Create Folder Structure
$OS_Families = $("W10x64","W7x64","S12","S16","W81x64","W81x86")
foreach ($OS_folder in $OS_Families) {
new-item -path "DS002:\Operating Systems" -enable "True" -Name "${OS_folder}" -Comments "" -ItemType "folder" 
new-item -path "DS002:\Packages" -enable "True" -Name "${OS_folder}" -Comments "" -ItemType "folder" 
new-item -path "DS002:\Task Sequences" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS002:\Applications" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS002:\Out-of-Box Drivers" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS002:\Selection Profiles" -enable "True" -Name "${OS_folder}" -Comments "" -Definition "<SelectionProfile><Include path=`"Applications\${OS_folder}`" /><Include path=`"Operating Systems\${OS_folder}`" /><Include path=`"Out-of-Box Drivers\${OS_folder}`" /><Include path=`"Packages\${OS_folder}`" /><Include path=`"Task Sequences\${OS_folder}`" /></SelectionProfile>" -ReadOnly "False" 
}

# Create Application structure for All OSs
new-item -path "DS002:\Applications" -enable "True" -Name "allOSs"  -Comments "" -ItemType "folder" -Verbose

# Create Folder Structure for vendors
$OS_Families = $("HP","Lenovo","Dell")
foreach ($OS_folder in $OS_Families) {
new-item -path "DS002:\Task Sequences" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" -Verbose
new-item -path "DS002:\Applications" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" -Verbose
new-item -path "DS002:\Out-of-Box Drivers" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" -Verbose
new-item -path "DS002:\Selection Profiles" -enable "True" -Name "${OS_folder}" -Comments "" -Definition "<SelectionProfile><Include path=`"Applications\${OS_folder}`" /><Include path=`"Out-of-Box Drivers\${OS_folder}`" /><Include path=`"Task Sequences\${OS_folder}`" /></SelectionProfile>" -ReadOnly "False" -Verbose
}


# Create Folder Structure for WinPE Drivers
$PE_Families = $("WinPE10x86", "WinPE10x64", "WinPE5x86", "WinPE5x64")
foreach ($OS_folder in $PE_Families) {
new-item -path "DS002:\Out-of-Box Drivers" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" -Verbose
new-item -path "DS002:\Selection Profiles" -enable "True" -Name "${OS_folder}" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\${OS_folder}`" /></SelectionProfile>" -ReadOnly "False" -Verbose
}


# Import Drivers for WinPE10x64
import-mdtdriver -path "DS002:\Out-of-Box Drivers\WinPE10x64" `
-SourcePath "e:\hp\HP WinPE Driver Packs\SP78464-WinPE10DriverPack\WinPE10_1.30\x64_winpe10\network" `
-Verbose
Read-Host "Modify the WinPE to include only drivers in their own Selection Profiles, press to continue"
