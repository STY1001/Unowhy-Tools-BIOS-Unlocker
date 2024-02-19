@echo off

powershell -window maximized -command ""

echo Please wait...

cd /d %~dp0\BIN

powershell -ExecutionPolicy Bypass -Command "& .\flash.ps1"

pause