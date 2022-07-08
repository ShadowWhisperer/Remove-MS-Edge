@echo off

::
:: Checks if Microsoft Edge is installed, and uninstall it and EdgeWebView
:: Only Works with the newer Edge, built on Chromium
::
:: Creator: ShadowWhisperer
::  Github: https://github.com/ShadowWhisperer
:: Created: 12/09/2020
:: Updated: 07/08/2022
::

:: Check if ran as Admin
net session >nul 2>&1 || (echo. & echo Run Script As Admin & echo. & pause & exit)

:: Set Exist Variable - Check if Edge is intalled  *Show Message, if not installed
set "EXIST=0"

:: Stop Edge Task
taskkill /im "msedge.exe" /f  >nul 2>&1


:: Uninstall - Edge
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\" (
for /f "delims=" %%a in ('dir /b "C:\Program Files (x86)\Microsoft\Edge\Application\"') do (
cd /d "C:\Program Files (x86)\Microsoft\Edge\Application\%%a\Installer\" >nul 2>&1
if exist "setup.exe" (
set "EXIST=1"
echo - Removing Microsoft Edge
start /w setup.exe --uninstall --system-level --force-uninstall)
))

:: Uninstall - EdgeWebView
if exist "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\" (
for /f "delims=" %%a in ('dir /b "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\"') do (
cd /d "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\%%a\Installer\" >nul 2>&1
if exist "setup.exe" (
echo - Removing EdgeWebView
start /w setup.exe --uninstall --msedgewebview --system-level --force-uninstall)
))


:: Delete Edge desktop icon, from all users
for /f "delims=" %%a in ('dir /b "C:\Users"') do (
del /S /Q "C:\Users\%%a\Desktop\edge.lnk" >nul 2>&1
del /S /Q "C:\Users\%%a\Desktop\Microsoft Edge.lnk" >nul 2>&1)

:: Delete additional files
if exist "C:\Windows\System32\MicrosoftEdgeCP.exe" (
for /f "delims=" %%a in ('dir /b "C:\Windows\System32\MicrosoftEdge*"') do (
takeown /f "C:\Windows\System32\%%a" > NUL 2>&1
icacls "C:\Windows\System32\%%a" /inheritance:e /grant "%UserName%:(OI)(CI)F" /T /C > NUL 2>&1
del /S /Q "C:\Windows\System32\%%a" > NUL 2>&1))



:: Not Installed
if "%EXIST%"=="0" echo. & echo Edge ^(Chromium^) Is Not Installed & echo. & timeout /t 3 & exit
