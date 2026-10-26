@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Ollama-Turbo-RTX.ps1"
pause
