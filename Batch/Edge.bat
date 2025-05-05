@echo off

REM
REM Download setup.exe from Repo
REM Check download / HASH
REM Remove Edge
REM Remove Extras
REM Remove APPX
REM

REM #Admin Permissions
net session >NUL 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)
title Edge Remover - 2/18/2025
set "expected=4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"

set "onHashErr=download"

set "fileSetup=%~dp0setup.exe"
if exist "%fileSetup%" goto file_check;
set "fileSetup=%tmp%\setup.exe"
if exist "%fileSetup%" goto file_check;

:file_download
set "onHashErr=error"
ipconfig | find "IPv" >NUL
if %errorlevel% neq 0 echo. & echo You are not connected to a network ! & echo. & pause & exit

echo - Downloading Required File
powershell -Command "try { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe', '%fileSetup%') } catch { Write-Host 'Error downloading the file.' }"
if not exist "%fileSetup%" echo File download failed. Check your internet connection & echo & pause & exit

:file_check
powershell -Command "exit ((Get-FileHash '%fileSetup%' -Algorithm SHA256).Hash.ToLower() -ne '%expected%')"
if %errorlevel% neq 0 goto file_%onHashErr%
echo. & goto uninst_edge

:file_error
echo File hash does not match the expected value. & echo & pause & exit


REM #Edge
:uninst_edge
echo - Removing Edge
where /q "%ProgramFiles(x86)%\Microsoft\Edge\Application:*"
if %errorlevel% equ 0 start /w "" "%fileSetup%" --uninstall --system-level --force-uninstall


REM #Additional Files

REM Desktop icon
:users_cleanup
echo - Removing Additional Files

set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Public') do ( call :user_rem_lnks_by_path %%d )
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Default') do ( call :user_rem_lnks_by_path %%d )
for /f "skip=1 tokens=7 delims=\" %%k in ('reg query "%REG_USERS_PATH%" /k /f "*"') do ( call :user_rem_lnks_by_sid %%k )
goto users_done

:user_rem_lnks_by_sid
if "%1"=="S-1-5-18" goto user_end
if "%1"=="S-1-5-19" goto user_end
if "%1"=="S-1-5-20" goto user_end
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%\%1" /v ProfileImagePath') do (
	call :user_rem_lnks_by_path %%d
	if "%UserProfile%"=="%%d" set "USER_SID=%1"
)
goto user_end

:user_rem_lnks_by_path
del /s /q "%1\Desktop\edge.lnk" >NUL 2>&1
del /s /q "%1\Desktop\Microsoft Edge.lnk" >NUL 2>&1

:user_end
exit /b 0

:users_done

REM System32
if exist "%SystemRoot%\System32\MicrosoftEdgeCP.exe" (
for /f "delims=" %%a in ('dir /b "%SystemRoot%\System32\MicrosoftEdge*"') do (
 takeown /f "%SystemRoot%\System32\%%a" >NUL 2>&1
 icacls "%SystemRoot%\System32\%%a" /inheritance:e /grant "%UserName%:(OI)(CI)F" /T /C >NUL 2>&1
 del /S /Q "%SystemRoot%\System32\%%a" >NUL 2>&1))

REM Folders
taskkill /im MicrosoftEdgeUpdate.exe /f >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Temp" >NUL 2>&1
rd /s /q "%AllUsersProfile%\Microsoft\EdgeUpdate" >NUL 2>&1

REM Files
del /s /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1

REM Registry
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >NUL 2>&1

REM Tasks - Files
for /r "%SystemRoot%\System32\Tasks" %%f in (*MicrosoftEdge*) do del "%%f" >NUL 2>&1

REM Tasks - Name
for /f "skip=1 tokens=1 delims=," %%a in ('schtasks /query /fo csv') do (
for %%b in (%%a) do (
 if "%%b"=="MicrosoftEdge" schtasks /delete /tn "%%~a" /f >NUL 2>&1))

REM Update Services
set "service_names=edgeupdate edgeupdatem"
for %%n in (%service_names%) do (
 sc stop %%n >NUL 2>&1
 sc delete %%n >NUL 2>&1
 reg delete "HKLM\SYSTEM\CurrentControlSet\Services\%%n" /f >NUL 2>&1
)


REM #APPX
echo - Removing APPX

if defined USER_SID goto rem_appX
for /f "delims=" %%a in ('powershell "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"') do set "USER_SID=%%a"

:rem_appX
set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName"') do (
    if not "%%a"=="" (
        reg add "%REG_APPX_STORE%\EndOfLife\%USER_SID%\%%a" /f >NUL 2>&1
        reg add "%REG_APPX_STORE%\EndOfLife\S-1-5-18\%%a" /f >NUL 2>&1
        reg add "%REG_APPX_STORE%\Deprovisioned\%%a" /f >NUL 2>&1
        powershell -Command "Remove-AppxPackage -Package '%%a'" 2>NUL
        powershell -Command "Remove-AppxPackage -Package '%%a' -AllUsers" 2>NUL
    )
)

REM %SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
 takeown /f "%%d" /r /d y >NUL 2>&1
 icacls "%%d" /grant administrators:F /t >NUL 2>&1
 rd /s /q "%%d" >NUL 2>&1)
