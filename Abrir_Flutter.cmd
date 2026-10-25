@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Dev.ps1" -Action Mobile %*
if errorlevel 1 (pause & exit /b 1)
