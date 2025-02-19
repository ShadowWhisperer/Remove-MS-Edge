@echo off

REM #Admin Permissions
net session >NUL 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)
title Edge Remover - 2/18/2025


REM #APPX
echo - Removing APPX

for /f "delims=" %%a in ('powershell "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"') do set "USER_SID=%%a"

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
