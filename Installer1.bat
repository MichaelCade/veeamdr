@echo off

setlocal
call :setESC

cls
echo %ESC%[101;93m stopping powershell %ESC%[0m
taskkill /IM "powershell.exe" /F
echo %ESC%[101;93m Installing Powershell For Azure Silently %ESC%[0m
msiexec /i "C:\Program Files\Veeam\Backup and Replication\Console\azure-powershell.5.1.1.msi" /Passive
:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0
