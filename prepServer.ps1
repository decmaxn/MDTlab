<# Notes:

Authors: Greg Shields
Modified by Victor Ma

Goal - Prepare the local machine by installing needed PowerShell Gallery modules.
This script must be run before configureServer.

Note:
Get-PackageSource will error out in Windows Server 2016 version 1607 Build 14393.447 installation with GUI, but it's not happening on the installation without GUI.
Error reported at https://github.com/OneGet/oneget/issues/183. 


Disclaimer

This example code is provided without copyright and AS IS.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>

Get-PackageSource -Name PSGallery | Set-PackageSource -Trusted -Force -ForceBootstrap

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module xComputerManagement -Force
Install-Module xNetworking -Force

Write-Host "You may now execute '.\configureServer.ps1'"