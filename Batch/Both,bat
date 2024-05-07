@echo off

::
:: Download setup.exe from Repo
:: Check download / HASH
:: Remove Edge
:: Remove Webview
:: Remove Extras
:: Remove APPX
::
::
::
::    Breaks Webview - If deleted
::  HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate
::
::


net session >nul 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)
title Edge Remover
set "expected=4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"


:#Portable
if exist "%~dp0setup.exe" (
    powershell -Command "$hash = (Get-FileHash '%~dp0setup.exe' -Algorithm SHA256).Hash.ToLower(); if ($hash -eq '%expected%') { exit 0 } else { exit 1 }"
    if %errorlevel% equ 1 (
        goto DownloadFile
    ) else (
        set SRC=%~dp0setup.exe
    )
) else (
    goto DownloadFile
)



echo.
echo - Removing Edge

:# Edge
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\" (
for /f "delims=" %%a in ('dir /b "C:\Program Files (x86)\Microsoft\Edge\Application\"') do (
start /w "%SRC%" --uninstall --system-level --force-uninstall))

:# EdgeWebView
if exist "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\" (
for /f "delims=" %%a in ('dir /b "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\"') do (
start /w "%SRC%" --uninstall --msedgewebview --system-level --force-uninstall))
::Delete empty folders
for /f "delims=" %%d in ('dir /ad /b /s "C:\Program Files (x86)\Microsoft\EdgeWebView" 2^>nul ^| sort /r') do rd "%%d" 2>nul



:# Additional Files
echo - Removing Additional Junk

:: Desktop icon
for /f "delims=" %%a in ('dir /b "C:\Users"') do (
del /S /Q "C:\Users\%%a\Desktop\edge.lnk" >nul 2>&1
del /S /Q "C:\Users\%%a\Desktop\Microsoft Edge.lnk" >nul 2>&1)

:: System32
if exist "C:\Windows\System32\MicrosoftEdgeCP.exe" (
for /f "delims=" %%a in ('dir /b "C:\Windows\System32\MicrosoftEdge*"') do (
takeown /f "C:\Windows\System32\%%a" > NUL 2>&1
icacls "C:\Windows\System32\%%a" /inheritance:e /grant "%UserName%:(OI)(CI)F" /T /C > NUL 2>&1
del /S /Q "C:\Windows\System32\%%a" > NUL 2>&1))

:: Folders
rmdir /q /s "C:\ProgramData\Microsoft\EdgeUpdate" > NUL 2>&1
rmdir /q /s "C:\Program Files (x86)\Microsoft\Temp" > NUL 2>&1

:: Files
del /S /Q "C:\Program Files (x86)\Microsoft\Edge\Edge.dat" > NUL 2>&1
del /S /Q "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" > NUL 2>&1

:: Registry
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >nul 2>&1
if not exist "C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe" reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >nul 2>&1

:: Tasks - Files
for /r "C:\Windows\System32\Tasks" %%f in (*MicrosoftEdge*) do del "%%f" > NUL 2>&1

:: Tasks - Name
for /f "skip=1 tokens=1 delims=," %%a in ('schtasks /query /fo csv') do (
for %%b in (%%a) do (
 if "%%b"=="MicrosoftEdge" schtasks /delete /tn "%%~a" /f >nul 2>&1))

:: Update Services
set "service_names=edgeupdate edgeupdatem"
for %%n in (%service_names%) do (
 sc delete %%n >nul 2>&1
 reg delete "HKLM\SYSTEM\CurrentControlSet\Services\%%n" /f >nul 2>&1
)

:: Folders - C:\Windows\SystemApps\Microsoft.MicrosoftEdge*
for /d %%d in ("C:\Windows\SystemApps\Microsoft.MicrosoftEdge*") do (
 takeown /f "%%d" /r /d y >nul 2>&1
 icacls "%%d" /grant administrators:F /t >nul 2>&1
 rd /s /q "%%d" >nul 2>&1)


:# APPX
echo - Removing APPX
setlocal enabledelayedexpansion
for /f "delims=" %%a in ('powershell "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"') do set "USER_SID=%%a"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-AppxPackage -AllUsers ^| Where-Object { $_.PackageFullName -like '*microsoftedge*' } ^| Select-Object -ExpandProperty PackageFullName"') do (
    if not "%%a"=="" (
        set "APP=%%a"
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\!USER_SID!\!APP!" /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\S-1-5-18\!APP!" /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\!APP!" /f >nul 2>&1
        powershell -Command "Remove-AppxPackage -Package '!APP!'" 2>nul
        powershell -Command "Remove-AppxPackage -Package '!APP!' -AllUsers" 2>nul
    )
)
endlocal






exit

:DownloadFile
set SRC=%tmp%\setup.exe
ipconfig | find "IPv" > nul
if %errorlevel% neq 0 echo. & echo You are not connected to a network ! & echo. & pause & exit
echo - Downloading Required File
powershell -Command "$url = 'https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe'; $path = '%tmp%\setup.exe'; try { (New-Object Net.WebClient).DownloadFile($url, $path) } catch { Write-Host 'Error downloading the file.' }"
::Check HASH
if exist "%tmp%\setup.exe" (
    powershell -Command "$hash = (Get-FileHash '%tmp%\setup.exe' -Algorithm SHA256).Hash.ToLower(); if ($hash -eq '%expected%') { exit 0 } else { exit 1 }"
    if %errorlevel% equ 1 (
        echo File hash does not match the expected value. & echo & pause & exit
    )
) else (
    echo File download failed. Check your internet connection & echo & pause & exit
)
