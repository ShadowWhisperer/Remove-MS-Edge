@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Remove AppX
REM Remove AppX remains
REM

title Edge Remover - 2/18/2025

REM Get executor SID (Win 2003(XP x64) and up)
for /f "skip=1 tokens=1,2 delims=," %%a in ('whoami /user /fo csv') do set "USER_SID=%%~b"
REM Check Admin permissions
net session >NUL 2>&1
if %errorlevel% equ 0 goto is_admin_done
REM When UAC disabled, elevation not works
if "%USER_SID%" equ "%~1" echo Please, enable UAC and try again & echo. & pause & exit /b 1
REM Elevate with psl (slow as hell; don't try go around cmd /c)
powershell -noprofile -c Start-Process -Verb RunAs "\"`\"%COMSpec%`\"\" \"/c `\"`\"%~0`\" `\"%USER_SID%`\"`\"\""
exit /b %errorlevel%
:is_admin_done

REM Admin permissions granted, executor SID is admin SID
set "ADMIN_SID=%USER_SID%"
REM When script elevates itself, the user SID should be passed as 1st argument
if "%~1" neq "" goto usid_set
REM User use Admin account or elevates script by hands
choice /c yn /n /m "Logged as Admin? [Y,N]"
REM Check for positive answer, anything else considered as No
if %errorlevel% equ 1 goto usid_done
echo Please, run script without elevation & echo. & pause & exit /b 1

:usid_set
REM bad input here is not my fault
set "USER_SID=%~1"

:usid_done


REM #AppX
echo - Removing AppX

set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName"') do (
	if "%%a" neq "" (
		reg add "%REG_APPX_STORE%\EndOfLife\%USER_SID%\%%a" /f >NUL 2>&1
		reg add "%REG_APPX_STORE%\EndOfLife\S-1-5-18\%%a" /f >NUL 2>&1
		reg add "%REG_APPX_STORE%\Deprovisioned\%%a" /f >NUL 2>&1
		powershell -Command "Remove-AppxPackage -Package '%%a' -User '%USER_SID%'" 2>NUL
		powershell -Command "Remove-AppxPackage -Package '%%a' -AllUsers" 2>NUL
	)
)



REM Delete remained packges
echo - Cleaning AppX remains
REM %SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
	takeown /f "%%~d" /r /d y >NUL 2>&1
	icacls "%%~d" /grant "%UserName%:F" /t /c >NUL 2>&1
	rd /s /q "%%~d" >NUL 2>&1
)
REM %ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*
for /d %%d in ("%ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*") do (
	takeown /f "%%~d" /r /d y >NUL 2>&1
	icacls "%%~d" /grant "%UserName%:F" /t /c >NUL 2>&1
	rd /s /q "%%~d" >NUL 2>&1
)
