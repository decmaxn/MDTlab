$MDT_Server = $(hostname)
$DS_Folder = "C:\DS1"
$DS_Name = "DS1"

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "${DS_Folder}"

# Update Desployment Share to get WinPEs
#$INI_Source = "H:\MDT\"
#Read-Host "Do you need to Upload CustomSettings.ini and Bootstrap.ini from $INI_Source after modify the hardcoded parameters, hostname etc? Press anykey to Skip..."
#Copy-Item -Path "${INI_Source}CustomSettings.ini.DS1" -Destination ${DS_Folder}\Control\CustomSettings.ini -PassThru
#Copy-Item -Path "${INI_Source}Bootstrap.ini.DS1" -Destination ${DS_Folder}\Control\Bootstrap.ini -PassThru

# Updating Deployment Share
# update-MDTDeploymentShare -path "DS001:" -Verbose -Force
update-MDTDeploymentShare -path "DS001:" -Verbose

# Copy over ISO file, so I can use it to boot VM withou involve WDS server. 
$VM_Host = "HLABS16CTX"
Copy-Item -Path \\${MDT_Server}\${DS_Name}$\Boot\LiteTouchPE_x64.iso -Destination \\${VM_Host}\c$\Temp\${MDT_Server}_${DS_Name}'$'_LiteTouchPE_x64.iso -PassThru
Copy-Item -Path \\${MDT_Server}\${DS_Name}$\Boot\LiteTouchPE_x86.iso -Destination \\${VM_Host}\c$\Temp\${MDT_Server}_${DS_Name}'$'_LiteTouchPE_x86.iso -PassThru