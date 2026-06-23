@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "DATA_DIR=%~1"
if "%DATA_DIR%"=="" set "DATA_DIR=%SCRIPT_DIR%..\data"
for %%I in ("%DATA_DIR%") do set "DATA_DIR=%%~fI"

set "DOWNLOAD_SMPLX=0"
if /I "%~2"=="smplx" set "DOWNLOAD_SMPLX=1"

where curl.exe >nul 2>nul
if errorlevel 1 (
    echo curl.exe was not found. Install curl or use a recent Windows version.
    goto :Fail
)

echo.
echo Target data directory:
echo   %DATA_DIR%
echo.
echo You need a CameraHMR account: https://camerahmr.is.tue.mpg.de/
set /p "CAMERAHMR_USERNAME=Username (CameraHMR): "
set /p "CAMERAHMR_PASSWORD=Password (CameraHMR): "

call :Download "camerahmr" "SMPL_NEUTRAL.pkl" "%DATA_DIR%\models\SMPL\SMPL_NEUTRAL.pkl" "%CAMERAHMR_USERNAME%" "%CAMERAHMR_PASSWORD%" || goto :Fail
call :Download "camerahmr" "cam_model_cleaned.ckpt" "%DATA_DIR%\pretrained-models\cam_model_cleaned.ckpt" "%CAMERAHMR_USERNAME%" "%CAMERAHMR_PASSWORD%" || goto :Fail
call :Download "camerahmr" "camerahmr_checkpoint_cleaned.ckpt" "%DATA_DIR%\pretrained-models\camerahmr_checkpoint_cleaned.ckpt" "%CAMERAHMR_USERNAME%" "%CAMERAHMR_PASSWORD%" || goto :Fail
call :Download "camerahmr" "model_final_f05665.pkl" "%DATA_DIR%\pretrained-models\model_final_f05665.pkl" "%CAMERAHMR_USERNAME%" "%CAMERAHMR_PASSWORD%" || goto :Fail
call :Download "camerahmr" "smpl_mean_params.npz" "%DATA_DIR%\smpl_mean_params.npz" "%CAMERAHMR_USERNAME%" "%CAMERAHMR_PASSWORD%" || goto :Fail

if not "%DOWNLOAD_SMPLX%"=="1" goto :DoneDownloads

echo.
echo You need a BEDLAM2 account: https://bedlam2.is.tue.mpg.de/
set /p "BEDLAM2_USERNAME=Username (BEDLAM2): "
set /p "BEDLAM2_PASSWORD=Password (BEDLAM2): "
call :Download "bedlam2" "checkpoints/camerahmr/bedlam_v1_v2.ckpt" "%DATA_DIR%\pretrained-models\bedlam_v1_v2.ckpt" "%BEDLAM2_USERNAME%" "%BEDLAM2_PASSWORD%" || goto :Fail

echo.
echo You need a SMPL-X account: https://smpl-x.is.tue.mpg.de/
set /p "SMPLX_USERNAME=Username (SMPL-X): "
set /p "SMPLX_PASSWORD=Password (SMPL-X): "
call :Download "smplx" "smplx_lockedhead_20230207.zip" "%DATA_DIR%\models\smplx_lockedhead_20230207.zip" "%SMPLX_USERNAME%" "%SMPLX_PASSWORD%" || goto :Fail

echo Extracting SMPL-X model...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DATA_DIR%\models\smplx_lockedhead_20230207.zip' -DestinationPath '%DATA_DIR%\models\smplx_neutral_head' -Force" || goto :Fail

:DoneDownloads

echo.
echo Done.
echo Data directory:
echo   %DATA_DIR%
set "SCRIPT_EXIT_CODE=0"
goto :Finish

:Fail
echo.
echo Download script failed. Check the messages above.
echo Data directory:
echo   %DATA_DIR%
set "SCRIPT_EXIT_CODE=1"
goto :Finish

:Finish
echo.
pause
exit /b %SCRIPT_EXIT_CODE%

:Download
set "DOMAIN=%~1"
set "SFILE=%~2"
set "OUTPUT=%~3"
set "USERNAME=%~4"
set "PASSWORD=%~5"

for %%I in ("%OUTPUT%") do if not exist "%%~dpI" mkdir "%%~dpI"

echo.
echo Downloading %SFILE%
curl.exe -L -k --fail --retry 3 ^
    --output "%OUTPUT%" ^
    --data-urlencode "username=%USERNAME%" ^
    --data-urlencode "password=%PASSWORD%" ^
    "https://download.is.tue.mpg.de/download.php?domain=%DOMAIN%&sfile=%SFILE%"

if errorlevel 1 (
    echo Failed to download %SFILE%
    exit /b 1
)
exit /b 0
