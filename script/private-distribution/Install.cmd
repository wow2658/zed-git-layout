@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
if errorlevel 1 (echo Installation failed. Read the error above. & pause & exit /b 1)
echo Installation complete. Use the Zed Git Layout shortcut.
pause
