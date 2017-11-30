$MDT_Server = "BW10Ent1703x64"
$DS_Name = "DS1"
$TempVM = "BW7Px64"
$RAMDisk = "I:\"

# Copy over ISO file, so I can use it to boot VM withou involve WDS server. 
if (! (Test-Path O:)) { 
    net use O: /delete
    net use O: "\\${MDT_Server}\${DS_Name}$" /user:hlab\du p@ssw0rd 
    }

Copy-Item -Path O:\Boot\LiteTouchPE_x64.iso -Destination ${RAMDisk}\${MDT_Server}_${DS_Name}'$'_LiteTouchPE_x64.iso -PassThru
#Copy-Item -Path O:\Boot\LiteTouchPE_x86.iso -Destination ${RAMDisk}\${MDT_Server}_${DS_Name}'$'_LiteTouchPE_x86.iso -PassThru


Write-Host "Creating Temp directory and VHD file in it..."
if (! (Test-Path ${RAMDisk}\Temp)) `
{ New-Item -ItemType Directory -Path ${RAMDisk} -Name Temp }

if (! (Test-Path ${RAMDisk}\Temp\${TempVM}.vhdx)) `
{ New-VHD -Path ${RAMDisk}\Temp\${TempVM}.vhdx -Dynamic -SizeBytes 40gb }

Write-Host "Creating Temp VM and attach NIC, VHD, ISO..."
$DefaultSwitch = $(Get-VMSwitch).Name
New-VM -Name ${TempVM} `
    -MemoryStartupBytes 3096MB `
    -VHDPath ${RAMDisk}\Temp\${TempVM}.vhdx `
    -SwitchName $DefaultSwitch `
    -BootDevice CD
Set-VM -VMName ${TempVM} -ProcessorCount 3
Get-VMDvdDrive -VMName ${TempVM} `
    | Set-VMDvdDrive -Path ${RAMDisk}\${MDT_Server}_${DS_Name}'$'_LiteTouchPE_x64.iso

Write-Host "Start the VM..."
Start-VM -Name ${TempVM}

Write-Host "The TempVM ${TempVM} was created and started, the Base Image should be Captured before the VM is shutdown"
