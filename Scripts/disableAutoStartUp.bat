@echo off
set TASK_FOLDER=\AutoKeyMap
set TASK_NAME=AutoKeyMap

echo.
echo ===== Uninstalling AutoKeyMap Task =====

schtasks /delete /tn "%TASK_FOLDER%\%TASK_NAME%" /f

if %errorlevel%==0 (
    echo AutoKeyMap removed successfully from folder %TASK_FOLDER%!
) else (
    echo Task not found or failed to remove!
)

pause
