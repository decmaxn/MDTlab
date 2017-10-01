$MDT_Server = $(hostname)
$DS_Folder = "C:\DS1"
$DS_Name = "DS1"
$DS_Desc = "MDT Builder"
$BuilderAccount = "du"

New-Item -Path "${DS_Folder}" -ItemType directory
# Creat the deployment share
New-SmbShare -Name "${DS_Name}$" -Path "${DS_Folder}" -FullAccess Administrators -ChangeAccess $BuilderAccount
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "${DS_Folder}" -Description ${DS_Desc} -NetworkPath "\\${MDT_Server}\${DS_Name}$"  | add-MDTPersistentDrive 
icacls.exe ${DS_Folder}\Captures /grant "${BuilderAccount}:(OI)(CI)(M)"

# Prepare for central Log folder
new-item -Path ${DS_Folder}\Logs -ItemType Directory
icacls.exe ${DS_Folder}\Logs /grant ""${BuilderAccount}":(OI)(CI)(M)"

# Create Folder Structure
$OS_Families = $("W10x64","W7x64","S12","S16","W81x64","W81x86")
foreach ($OS_folder in $OS_Families) {
new-item -path "DS001:\Operating Systems" -enable "True" -Name "${OS_folder}" -Comments "" -ItemType "folder" 
new-item -path "DS001:\Packages" -enable "True" -Name "${OS_folder}" -Comments "" -ItemType "folder" 
new-item -path "DS001:\Task Sequences" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS001:\Applications" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS001:\Out-of-Box Drivers" -enable "True" -Name "${OS_folder}"  -Comments "" -ItemType "folder" 
new-item -path "DS001:\Selection Profiles" -enable "True" -Name "${OS_folder}" -Comments "" -Definition "<SelectionProfile><Include path=`"Applications\${OS_folder}`" /><Include path=`"Operating Systems\${OS_folder}`" /><Include path=`"Out-of-Box Drivers\${OS_folder}`" /><Include path=`"Packages\${OS_folder}`" /><Include path=`"Task Sequences\${OS_folder}`" /></SelectionProfile>" -ReadOnly "False" 
}
