@echo off
title Unowhy Tools BIOS Unlocker

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -window maximized -command ""

echo Launching Unowhy Tools BIOS Unlocker...

cd /d "%~dp0\BIN"
powershell -ExecutionPolicy Bypass -File ".\flash.ps1"

echo.
pause
exit /b 0
