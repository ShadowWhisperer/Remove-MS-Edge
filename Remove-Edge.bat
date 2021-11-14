@echo off

::
:: Checks if Microsoft Edge(Chromium Based)is installed, and uninstall it
:: Only Works with the newer Edge built on Chromium
::
:: Creator: ShadowWhisperer
::  Github: https://github.com/ShadowWhisperer
:: Created: 12/09/2020
:: Updated: 11/14/2021
::

:: Check if ran as Admin
net session >nul 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)

:: Set Exist Variable - Check if Edge is intalled  *Show Message, if not installed
set "EXIST=0"

:: Stop Edge Task
taskkill /im "msedge.exe" /f  >nul 2>&1

::Do not install Edge from Windows Updates (Does not appear to work anymore)
reg add HKLM\SOFTWARE\Microsoft\EdgeUpdate /t REG_DWORD /v DoNotUpdateToEdgeWithChromium /d 1 /f >nul 2>&1

:: Uninstall - 32Bit
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\" (
set "EXIST=1"
for /f "delims=" %%a in ('dir /b "C:\Program Files (x86)\Microsoft\Edge\Application\"') do (
cd /d "C:\Program Files (x86)\Microsoft\Edge\Application\%%a\Installer\"
if exist "setup.exe" (
echo - Removing Microsoft Edge
start /w setup.exe --uninstall --system-level --force-uninstall)
echo Finished
timeout /t 3 & exit
))

:: Uninstall - 64Bit
if exist "C:\Program Files\Microsoft\Edge\Application\" (
set "EXIST=1"
for /f "delims=" %%a in ('dir /b "C:\Program Files\Microsoft\Edge\Application\"') do (
cd /d "C:\Program Files\Microsoft\Edge\Application\%%a\Installer\"
if exist "setup.exe" (
echo - Removing Microsoft Edge
start /w setup.exe --uninstall --system-level --force-uninstall)
echo Finished
timeout /t 3 & exit
))


:: Delete Edge icon from the desktop of all users
for /f "delims=" %%a in ('dir /b "C:\Users"') do del /S /Q "C:\Users\%%a\Desktop\edge.lnk" >nul 2>&1

:: Not Installed
if "%EXIST%"=="0" echo. & echo Edge ^(Chromium^) Is Not Installed & echo. & timeout /t 3 & exit
