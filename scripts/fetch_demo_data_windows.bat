@echo off
setlocal

cd /d "%~dp0\.."

if not "%~1"=="" goto :RunWithArgs

echo CameraHMR demo data downloader
echo.
echo Press Enter to use the default repository data directory:
echo   %CD%\data
echo.
set /p "DATA_DIR=Data directory: "
if "%DATA_DIR%"=="" set "DATA_DIR=data"

echo.
echo Choose model type:
echo   smpl  - normal CameraHMR demo
echo   smplx - BEDLAM2 / SMPL-X demo extras
echo.
set /p "MODE=Model type [smpl]: "
if "%MODE%"=="" set "MODE=smpl"

echo.
set /p "FORCE=Force re-download existing files? [y/N]: "
if /I "%FORCE%"=="y" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_demo_data_windows.ps1" "%DATA_DIR%" "%MODE%" -Force
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_demo_data_windows.ps1" "%DATA_DIR%" "%MODE%"
)
goto :Finish

:RunWithArgs
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_demo_data_windows.ps1" %*

:Finish
set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %SCRIPT_EXIT_CODE%
