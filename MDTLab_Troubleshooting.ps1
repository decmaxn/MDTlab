$MDT_Server = $(hostname)
$DS_Folder = "C:\DS2"
$DS_Path = "DS002"
$INI_Source = "C:\Users\da\Downloads"

$DaRT_Package = "E:\Windows Deployment\Microsoft\DaRT10x64\MSDaRT100.msi"

$Package_Share = "\\S12GuiMDT\e$"
if (! (Test-Path E:)) {
    net use E: /delete
    net use E: $Package_Share
    }


# MDT install first
Start-Process -FilePath ${DaRT_Package} -ArgumentList '/passive /norestart' -wait -PassThru


if (! (Test-Path "${DS_Folder}\Tools\x64\Toolsx64.cat") -or ! (Test-Path "${DS_Folder}\Tools\x86\Toolsx86.cat")) {
    copy "C:\Program Files\Microsoft DaRT\v10\Toolsx64.cab" "${DS_Folder}\Tools\x64" 
    copy "C:\Program Files\Microsoft DaRT\v10\Toolsx86.cab" "${DS_Folder}\Tools\x86"
}

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "${DS_Path}" -PSProvider "MDTProvider" -Root ${DS_Folder}

if (! (Test-Path $INI_Source\WinPE\x64\CMTrace64.exe)) {Read-Host "Copy CMTrace64.exe to $INI_Source\WinPEx64 folder and press anykey" }
Write-Host "Right clieck the Desployment Share and choose Property"
Write-host "Put $INI_Source\WinPE\x64 in 'Extra Directory to add' for platform x64 in 'Windows PE' tab"
Read-Host "Click OK, wait for it to close up, and press any key to contiue here."
update-MDTDeploymentShare -path "${DS_Path}:"