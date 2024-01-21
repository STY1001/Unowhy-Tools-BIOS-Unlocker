@echo off

echo Please wait...

cd /d %~dp0\BIN

powershell -noexit -ExecutionPolicy Bypass -Command "& .\flash.ps1"