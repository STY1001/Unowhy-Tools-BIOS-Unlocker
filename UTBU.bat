@echo off

powershell -window maximized -command ""

title Unowhy Tools BIOS Unlocker
echo Launching Unowhy Tools BIOS Unlocker... 

cd /d %~dp0\BIN

powershell -ExecutionPolicy Bypass -Command "& .\flash.ps1"

echo.

pause
exit 0