@echo off
reg query hklm\software\Microsoft\Windows\CurrentVersion\policies\System /v EnableLUA
reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
reg query hklm\software\Microsoft\Windows\CurrentVersion\policies\System /v EnableLUA
echo "Please confirm the change by comparing query result before/after"
echo "Ctrl-Break to run it in elevated DOS prompt if it not changed"
echo "Or it will reboot to take effect of disabling UAC"
pause
shutdown /r /t 000