@echo off
setlocal

cd /d "%~dp0\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_demo_data_windows.ps1" %*
set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %SCRIPT_EXIT_CODE%
