@echo off
setlocal enabledelayedexpansion

:: -----------------------------
:: 配置任务名和路径
:: -----------------------------
set TASK_FOLDER=\AutoKeyMap
set TASK_NAME=AutoKeyMap
set EXE_PATH=%~dp0..\AutoKeyMap.exe
set XML_FILE=%~dp0AutoKeyMapTask.xml

echo.
echo ===== Installing AutoKeyMap Task =====

:: 检查 exe 是否存在
if not exist "%EXE_PATH%" (
    echo AutoKeyMap.exe not found at "%EXE_PATH%"
    pause
    exit /b
)

:: 删除旧任务（如果存在）
schtasks /query /tn "%TASK_FOLDER%\%TASK_NAME%" >nul 2>&1
if %errorlevel%==0 (
    echo Removing old task...
    schtasks /delete /tn "%TASK_FOLDER%\%TASK_NAME%" /f >nul
)

:: -----------------------------
:: 获取当前用户名和 SID
:: -----------------------------
set USER_NAME=%USERNAME%
for /f "tokens=2" %%s in ('whoami /user /fo list ^| find "SID"') do set USER_SID=%%s

:: -----------------------------
:: 生成 XML 模板到当前目录
:: -----------------------------
(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Author^>!USER_NAME!^</Author^>
echo     ^<URI^>%TASK_FOLDER%\%TASK_NAME%^</URI^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<LogonTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo     ^</LogonTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<UserId^>!USER_SID!^</UserId^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^>
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo     ^<IdleSettings^>
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
echo     ^</IdleSettings^>
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^>
echo     ^<Enabled^>true^</Enabled^>
echo     ^<Hidden^>false^</Hidden^>
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^>
echo     ^<UseUnifiedSchedulingEngine^>true^</UseUnifiedSchedulingEngine^>
echo     ^<WakeToRun^>false^</WakeToRun^>
echo     ^<ExecutionTimeLimit^>PT0S^</ExecutionTimeLimit^>
echo     ^<Priority^>7^</Priority^>
echo     ^<RestartOnFailure^>
echo       ^<Interval^>PT1M^</Interval^>
echo       ^<Count^>3^</Count^>
echo     ^</RestartOnFailure^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>%EXE_PATH%^</Command^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_FILE%"

:: -----------------------------
:: 导入任务
:: -----------------------------
schtasks /create /tn "%TASK_FOLDER%\%TASK_NAME%" /xml "%XML_FILE%" /f

if %errorlevel%==0 (
    echo AutoKeyMap installed successfully in folder %TASK_FOLDER%.
) else (
    echo Failed to install AutoKeyMap.
)

pause
