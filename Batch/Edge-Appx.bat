@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Remove AppX
REM Remove AppX remains
REM

set "ISSUE_GENERIC=1"
set "ISSUE_UAC=2"
set "ISSUE_NETWORK=3"
set "ISSUE_DOWNLOAD=4"
set "ISSUE_HASH=5"

REM set logging verbosity ( log_lvl.none, log_lvl.errors, log_lvl.debug )
call :log_lvl.debug

title Edge Remover - 2/18/2025



REM Get executor SID (Win 2003(XP x64) and up)
for /f "skip=1 tokens=1,2 delims=," %%a in ('whoami /user /fo csv') do set "USER_SID=%%~b"
REM Check Admin permissions
net session >NUL 2>&1
if %errorlevel% equ 0 goto uac.success
REM When UAC disabled, elevation not works
if "%USER_SID%" equ "%~1" echo Please, enable UAC and try again & echo. & pause & exit /b %ISSUE_UAC%
REM Elevate with psl (don't try go around cmd /c; see Both.bat for quotes details)
echo Start-Process -Verb RunAs """$env:COMSpec""" "/c """"%~0"" ""%USER_SID%"""""|powershell -noprofile - %bat_log%
exit /b %errorlevel%
:uac.success

REM Admin permissions granted, executor SID is admin SID
set "ADMIN_SID=%USER_SID%"
REM When script elevates itself, the user SID should be passed as 1st argument
if "%~1" neq "" goto uac.usid_set
REM User use Admin account or elevates script by hands
choice /c yn /n /m "Logged as Admin? [Y,N]"
REM Check for positive answer, anything else considered as No
if %errorlevel% equ 1 goto uac.done
echo Please, run script without elevation & echo. & pause & exit /b %ISSUE_UAC%

:uac.usid_set
REM bad input here is not my fault
set "USER_SID=%~1"

:uac.done



REM #AppX
echo - Removing AppX

set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName"') do (
	if "%%a" neq "" (
		reg add "%REG_APPX_STORE%\EndOfLife\%USER_SID%\%%a" /f %bat_log%
		reg add "%REG_APPX_STORE%\EndOfLife\S-1-5-18\%%a" /f %bat_log%
		reg add "%REG_APPX_STORE%\Deprovisioned\%%a" /f %bat_log%
		powershell -Command "Remove-AppxPackage -Package '%%a' -User '%USER_SID%'" %bat_log%
		powershell -Command "Remove-AppxPackage -Package '%%a' -AllUsers" %bat_log%
	)
)



REM Delete remained packages
echo - Cleaning AppX remains
REM %SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
	takeown /f "%%~d" /r /d y %bat_dbg%
	icacls "%%~d" /grant "%UserName%:F" /t /c %bat_dbg%
	rd /s /q "%%~d" %bat_log%
)
REM %ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*") do (
	takeown /f "%%~d" /r /d y %bat_dbg%
	icacls "%%~d" /grant "%UserName%:F" /t /c %bat_dbg%
	rd /s /q "%%~d" %bat_log%
)



REM Main script end
echo - Edge removal complete
exit /b 0



REM levels of logging verbosity

:log_lvl.none
REM release mode
set "bat_log=>NUL 2>&1"
set "bat_dbg=>NUL 2>&1"
exit /b 0

:log_lvl.errors
REM errors only
set "bat_log=>NUL"
set "bat_dbg=>NUL 2>&1"
exit /b 0

:log_lvl.debug
REM debug mode, put all output to file(except user-trageted output)
set "bat_log=>>"%~dpn0_dbg.log" 2>&1"
set "bat_dbg=>>"%~dpn0_dbg.log" 2>&1"
REM resolves issue with accessing log file on elevation
timeout /t 1 /nobreak >NUL 2>&1
REM reset log file if this is not elevation re-run (bad check, cuz someone may pass an argument)
if "%~1" equ "" echo %~nx0 >"%~dpn0_dbg.log"
exit /b 0
