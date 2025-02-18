@echo off

:#Admin Permissions
net session >nul 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)
title Edge Remover - 2/18/2025


:# APPX
echo - Removing APPX

for /f "delims=" %%a in ('powershell "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"') do set "USER_SID=%%a"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName"') do ( 
    if not "%%a"=="" ( 
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\%USER_SID%\%%a" /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\S-1-5-18\%%a" /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%%a" /f >nul 2>&1
        powershell -Command "Remove-AppxPackage -Package '%%a'" 2>nul
        powershell -Command "Remove-AppxPackage -Package '%%a' -AllUsers" 2>nul
    )
)

:# %SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
 takeown /f "%%d" /r /d y >nul 2>&1
 icacls "%%d" /grant administrators:F /t >nul 2>&1
 rd /s /q "%%d" >nul 2>&1)
