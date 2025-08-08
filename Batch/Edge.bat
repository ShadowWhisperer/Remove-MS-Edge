@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Download setup.exe from Repo
REM Check download / HASH
REM Remove Edge
REM Remove AppX
REM Remove Edge remains
REM Remove AppX remains
REM Remove Extras
REM

title Edge Remover - 6/16/2025

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


set "expected=4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"
set "onHashErr=download"

set "fileSetup=%~dp0setup.exe"
if exist "%fileSetup%" goto file_check
set "fileSetup=%tmp%\setup.exe"
if exist "%fileSetup%" goto file_check

:file_download
set "onHashErr=error"
ipconfig | find "IPv" >NUL
if %errorlevel% neq 0 echo. & echo You are not connected to a network ! & echo. & pause & exit /b 2

echo - Downloading Required File
powershell -Command "try { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe', '%fileSetup%') } catch { Write-Host 'Error downloading the file.' }"
if not exist "%fileSetup%" echo File download failed. Check your internet connection & echo & pause & exit /b 2

:file_check
powershell -Command "Import-Module Microsoft.PowerShell.Utility; exit ((Get-FileHash '%fileSetup%' -Algorithm SHA256).Hash.ToLower() -ne '%expected%')"
if %errorlevel% neq 0 goto file_%onHashErr%
echo. & goto file_done

:file_error
echo File hash does not match the expected value. & echo. & pause & exit /b 3

:file_done


REM #Uninstall
echo - Removing Edge
where /q "%ProgramFiles(x86)%\Microsoft\Edge\Application:*"
if %errorlevel% neq 0 goto uninstall_edge_done
taskkill /im MicrosoftEdgeUpdate.exe /f /t >NUL 2>&1
start /w "" "%fileSetup%" --uninstall --system-level --force-uninstall
:uninstall_edge_done


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



REM #Cleanup
echo - Cleaning Edge remains
REM Delete Edge empty folders
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Temp" >NUL 2>&1
rd /s /q "%AllUsersProfile%\Microsoft\EdgeUpdate" >NUL 2>&1

REM Delete Edge Update Tasks
for /f "tokens=1 delims=," %%n in ('schtasks /query /fo csv') do ( call :task_remove "%%~n" )

REM Delete Edge Update Services
set "service_names=edgeupdate edgeupdatem microsoftedgeelevationservice"
for %%n in (%service_names%) do (
	sc stop %%n >NUL 2>&1
	sc delete %%n >NUL 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\%%n" /f >NUL 2>&1
)

REM Delete Desktop, StartMenu and TaskBar shortcuts
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Public') do ( call :user_lnks_remove_by_path "%%~d" )
del /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Default') do ( call :user_lnks_remove_by_path "%%~d" )
for /f "skip=1 tokens=7 delims=\" %%k in ('reg query "%REG_USERS_PATH%" /k /f "*"') do ( call :user_lnks_remove_by_sid %%k )


echo - Cleaning AppX remains
REM Delete remained packges
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



REM #Additional Data
echo - Removing additional data
REM Registry
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >NUL 2>&1

REM System32
for %%f in ("%SystemRoot%\System32\MicrosoftEdge*.exe") do (
	takeown /f "%%~f" >NUL 2>&1
	icacls "%%~f" /grant "%UserName%:F" /c >NUL 2>&1
	del /q "%%~f" >NUL 2>&1
)


REM Malformed Keys
echo - Fixing Registry
setlocal EnableDelayedExpansion
set "reg_path=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "tokens=*" %%k in ('reg query "%reg_path%" /s 2^>NUL ^| findstr /b /i "%reg_path%"') do (
	set "full_key=%%k"
	set "delete_key=false"
	set "reason="
	for %%a in ("!full_key!") do set "key_name=%%~nxa"
	REM Skip empty or unchanged names
	if "!key_name!"=="" (
		set "reason=empty key name"
	) else if "!key_name!"=="!full_key!" (
		set "reason=key name same as full path"
	) else (
		REM Check for space
		set "spaced_key=!key_name: =!"
		if not "!key_name!"=="!spaced_key!" (
			set "delete_key=true"
		) else (
			REM Check for letters
			echo /7 - !key_name! | findstr /r /c:"[a-zA-Z]" >NUL
			if !errorlevel! neq 0 set "delete_key=true"
		)
	)
	if "!delete_key!"=="true" reg delete "!full_key!" /f >nul 2>&1
)
endlocal



REM Main script end
exit /b 0


REM functions
REM labels, starts with underscore( _ ), are for internal usage and should not be called from main script
REM labels, starts with regular symbol, are public functions and can be called from main script

REM remove task by name
:task_remove
set "task_name=%~1"
if "%task_name:~0,1%" neq "\" goto _task_remove_end
if "%task_name:\MicrosoftEdge=%" equ "%task_name%" goto _task_remove_end
schtasks /end /tn "%task_name%" >NUL 2>&1
schtasks /delete /tn "%task_name%" /f >NUL 2>&1
del "%SystemRoot%\System32\Tasks%task_name%" >NUL 2>&1

:_task_remove_end
exit /b 0

REM retrieve location of user profile by user SID and call shortcuts removing
:user_lnks_remove_by_sid
if "%1" equ "S-1-5-18" goto _user_lnks_remove_end
if "%1" equ "S-1-5-19" goto _user_lnks_remove_end
if "%1" equ "S-1-5-20" goto _user_lnks_remove_end
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%\%1" /v ProfileImagePath') do ( call :user_lnks_remove_by_path "%%~d" )
goto _user_lnks_remove_end

REM remove shortcuts from several locations of user profile
:user_lnks_remove_by_path
del /q "%~1\Desktop\edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\edge.lnk" >NUL 2>&1
del /q "%~1\Desktop\Microsoft Edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" >NUL 2>&1
del /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" >NUL 2>&1

:_user_lnks_remove_end
exit /b 0
