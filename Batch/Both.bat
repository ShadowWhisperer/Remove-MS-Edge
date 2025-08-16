@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Download setup.exe from Repo
REM Check download / HASH
REM Remove Edge
REM Remove WebView
REM Remove AppX
REM Remove Edge remains
REM Remove WebView remains
REM Remove AppX remains
REM Remove Extras
REM

set "ISSUE_GENERIC=1"
set "ISSUE_UAC=2"
set "ISSUE_NETWORK=3"
set "ISSUE_DOWNLOAD=4"
set "ISSUE_HASH=5"

REM set logging verbosity ( log_lvl.none, log_lvl.errors, log_lvl.debug )
call :log_lvl.debug

title Edge Remover - 6/16/2025



REM Get executor SID (Win 2003(XP x64) and up)
for /f "skip=1 tokens=1,2 delims=," %%a in ('whoami /user /fo csv') do set "USER_SID=%%~b"
REM Check Admin permissions
net session >NUL 2>&1
if %errorlevel% equ 0 goto uac.success
REM When UAC disabled, elevation not works
if "%USER_SID%" equ "%~1" echo Please, enable UAC and try again & echo. & pause & exit /b %ISSUE_UAC%
REM Elevate with psl (slow as hell; don't try go around cmd /c)
powershell -noprofile -c Start-Process -Verb RunAs "\"`\"%COMSpec%`\"\" \"/c `\"`\"%~0`\" `\"%USER_SID%`\"`\"\"" %bat_log%
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



set "expected=4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"
set "onHashErr=download"

set "fileSetup=%~dp0setup.exe"
if exist "%fileSetup%" goto file.check
set "fileSetup=%tmp%\setup.exe"
if exist "%fileSetup%" goto file.check

:file.download
set "onHashErr=error"
ipconfig | find "IPv" >NUL 2>&1
if %errorlevel% neq 0 echo. & echo You are not connected to a network ! & echo. & pause & exit /b %ISSUE_NETWORK%

echo - Downloading Required File
powershell -Command "try { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe', '%fileSetup%') } catch { Write-Host 'Error downloading the file.' }"
if not exist "%fileSetup%" echo File download failed. Check your internet connection & echo & pause & exit /b %ISSUE_DOWNLOAD%

:file.check
powershell -Command "Import-Module Microsoft.PowerShell.Utility; exit ((Get-FileHash '%fileSetup%' -Algorithm SHA256).Hash.ToLower() -ne '%expected%')"
if %errorlevel% neq 0 goto file.%onHashErr%
echo. & goto file.done

:file.error
echo File hash does not match the expected value. & echo. & pause & exit /b %ISSUE_HASH%

:file.done



REM #Uninstall
echo - Removing Edge
where "%ProgramFiles(x86)%\Microsoft\Edge\Application:*" %bat_log%
if %errorlevel% neq 0 goto uninstall.edge.done
taskkill /im MicrosoftEdgeUpdate.exe /f /t %bat_log%
start /w "" "%fileSetup%" --uninstall --system-level --force-uninstall %bat_log%
:uninstall.edge.done


echo - Removing WebView
where "%ProgramFiles(x86)%\Microsoft\EdgeWebView\Application:*" %bat_log%
if %errorlevel% neq 0 goto uninstall.webview.done
start /w "" "%fileSetup%" --uninstall --msedgewebview --system-level --force-uninstall %bat_log%
:uninstall.webview.done


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



REM #Cleanup
echo - Cleaning Edge remains
REM Delete Edge empty folders
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" %bat_log%
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" %bat_log%
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" %bat_log%
rd /s /q "%ProgramFiles(x86)%\Microsoft\Temp" %bat_log%
rd /s /q "%AllUsersProfile%\Microsoft\EdgeUpdate" %bat_log%

REM Delete Edge Update Tasks
for /f "tokens=1 delims=," %%n in ('schtasks /query /fo csv') do ( call :task_remove "%%~n" %bat_log% )

REM Delete Edge Update Services
set "service_names=edgeupdate edgeupdatem microsoftedgeelevationservice"
for %%n in (%service_names%) do ( call :service_remove "%%~n" %bat_log% )

REM Delete Desktop, StartMenu and TaskBar shortcuts; cleanup user registry
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Public') do ( call :user_lnks_remove_by_path "%%~d" %bat_log% )
del /f /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" %bat_log%
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Default') do (
	call :user_lnks_remove_by_path "%%~d" %bat_log%
	call :user_reg_cleanup .DEFAULT "%%~d" %bat_log%
)
for /f "skip=1 tokens=7 delims=\" %%k in ('reg query "%REG_USERS_PATH%" /k /f "*"') do ( call :user_cleanup_by_sid %%k %bat_log% )


echo - Cleaning WebView remains
REM Delete WebView empty folders
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeWebView" %bat_log%


echo - Cleaning AppX remains
REM Delete remained packages
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



REM #Additional Data
echo - Removing additional data
REM Registry
reg delete "HKLM\SOFTWARE\Classes\AppID\MicrosoftEdgeUpdate.exe" /f %bat_log%
reg delete "HKLM\SOFTWARE\Classes\AppID\{1FCBE96C-1697-43AF-9140-2897C7C69767}" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\MicrosoftEdge" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation" /f %bat_log%
reg delete "HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration" /f %bat_log%
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f %bat_log%
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f %bat_log%
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\MicrosoftEdge" /f %bat_log%

set "reg_HKLM_keys_del="
REM Keys for TakeOwn+FullControl and deleting, max length after batch vars expanding - 8167(8191 - 24; 24 - "set "reg_HKLM_keys_del="")
REM delimiter is \\, any other chars is allowed in key name; values can contains even backslash
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\Windows\CurrentVersion\MicrosoftEdge" %bat_log%
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\MicrosoftEdge" %bat_log%
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.BCHostServer" %bat_log%
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.ContentProcessServer" %bat_log%
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.F12Server" %bat_log%

call :reg_HKLM_keys_access_and_delete %bat_log%

REM System32
for %%f in ("%SystemRoot%\System32\MicrosoftEdge*.exe") do (
	takeown /f "%%~f" %bat_log%
	icacls "%%~f" /grant "%UserName%:F" /c %bat_log%
	del /f /q "%%~f" %bat_log%
)


REM Malformed Keys
echo - Fixing registry
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
echo - Edge removal complete
exit /b 0



REM =====  Functions  =====

REM labels, starts with underscore( _ ), are for internal usage and should not be called from main script
REM labels, starts with regular symbol, are public functions and can be called from main script


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


REM remove task by name if name match pattern
:task_remove
set "task_name=%~1"
if "%task_name:~0,1%" neq "\" goto _task_remove.end
if "%task_name:\MicrosoftEdge=%" equ "%task_name%" goto _task_remove.end
schtasks /end /tn "%task_name%"
schtasks /delete /tn "%task_name%" /f
del /f /q "%SystemRoot%\System32\Tasks%task_name%"

:_task_remove.end
exit /b 0


REM remove service by name
:service_remove
sc stop "%~1"
if %errorlevel% equ 1060 goto _service_remove.end
sc delete "%~1"
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /f

:_service_remove.end
exit /b 0


REM retrieve location of user profile by user SID
REM call shortcuts removing
REM call cleanup of user registry
:user_cleanup_by_sid
if "%1" equ "S-1-5-18" goto _user_cleanup_by_sid.end
if "%1" equ "S-1-5-19" goto _user_cleanup_by_sid.end
if "%1" equ "S-1-5-20" goto _user_cleanup_by_sid.end
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%\%1" /v ProfileImagePath') do ( set "profile_path=%%~d" )
call :user_lnks_remove_by_path "%profile_path%"
call :user_reg_cleanup %1 "%profile_path%"

:_user_cleanup_by_sid.end
exit /b 0

REM remove shortcuts from several locations of user profile
:user_lnks_remove_by_path
del /f /q "%~1\Desktop\edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\edge.lnk"
del /f /q "%~1\Desktop\Microsoft Edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk"
del /f /q "%~1\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"

exit /b 0

REM remove some registry keys
REM arguments: user SID and user profile dir path in this exact order
:user_reg_cleanup
reg query "HKU\%1" /ve
if %errorlevel% neq 0 reg load "HKU\%1" "%~2\NTUSER.DAT"
if %errorlevel% neq 0 goto _user_reg_cleanup.cls

reg delete "HKU\%1\SOFTWARE\Microsoft\Edge" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\EdgeUpdate" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\MicrosoftEdge" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration" /f
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\Edge" /f
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\MicrosoftEdge" /f

reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge-holographic" /f

REM for current user require explorer restart
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesRemovedChanges" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesVersion" /f
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesChanges" /f

:_user_reg_cleanup.cls
REM for user profiles "SOFTWARE\Classes" is a symlink, for internal profiles it's a real key
REM usually symlinks created by windows after hive load
REM but it's a bit complicated process(especially for batch) and not worth it here (i can talk!)
set "cls_path=%1\SOFTWARE\Classes"
reg query "HKU\%cls_path%" /ve
if %errorlevel% equ 0 goto _user_reg_cleanup.cls.ready

set "cls_path=%1_Classes"
reg query "HKU\%cls_path%" /ve
REM location of user classes hive can be altered by user
if %errorlevel% neq 0 reg load "HKU\%cls_path%" "%~2\AppData\Local\Microsoft\Windows\UsrClass.dat"
if %errorlevel% neq 0 goto _user_reg_cleanup.end

:_user_reg_cleanup.cls.ready

reg delete "HKU\%cls_path%\microsoft-edge" /f
reg delete "HKU\%cls_path%\microsoft-edge-holographic" /f

:_user_reg_cleanup.end
exit /b 0



REM =====  PowerShell(psl) based complex functions  =====

REM psl code passed via stdin
REM code length should not exceed 8146 chars after batch vars expanding(8191 - 5 - 40; 5 - "echo "; 40 - call of psl?)
REM batch escape chars(^) and new lines(\r\n; unless escaped _properly_) not counts
REM to be continued, line must ends with ^ . first char of the next line will be escaped!
REM when next line starts with escaping of another char remove one ^
REM when next line starts with double quoted string, percent or ^(cuz empty) put space or semicolon ahead
REM in the end this is a single line! put ; where command(line) ends and be careful with one-line comment
REM in-code char escaping(for passing to psl via stdin from batch; do not confuse with batch nor psl levels):
REM anywhere: % as %% ; ^ as ^^^^ ; & as ^^^& ; < as ^^^< ; > as ^^^> ; | as ^^^| ; " as ^^^" (unpaired only)
REM between double quotes: % as %% ; " as "" (simplification, resolves psl escaping as well); rest not required
REM https://ss64.com/nt/syntax-esc.html

REM most(or all) of the functions here have no own arguments and simply checks env-vars, prepared for psl code
REM env-vars used to shorts psl code since they are easily accessible from it as from child process


REM get access and delete registry keys in HKLM hive
REM keys for TakeOwn+FullControl ONLY should be in reg_HKLM_keys_acs var
REM keys that also should be deleted - in reg_HKLM_keys_del var
REM DO NOT pass keys with values at tail
:reg_HKLM_keys_access_and_delete
if defined reg_HKLM_keys_acs goto _reg_HKLM_keys_access_and_delete.psl
if not defined reg_HKLM_keys_del goto _reg_HKLM_keys_access_and_delete.end
:_reg_HKLM_keys_access_and_delete.psl
echo ;^
if ($env:reg_HKLM_keys_acs) { $key_paths_acs = $env:reg_HKLM_keys_acs.Trim().Split([string[]]"\\", [StringSplitOptions]::RemoveEmptyEntries) }^
if ($env:reg_HKLM_keys_del) { $key_paths_del = $env:reg_HKLM_keys_del.Trim().Split([string[]]"\\", [StringSplitOptions]::RemoveEmptyEntries) }^
$key_paths_acs += $key_paths_del;^
if (!$key_paths_acs) { exit }^
$user_ident = [System.Security.Principal.NTAccount]$env:UserName;^
$access_rule = [System.Security.AccessControl.RegistryAccessRule]::new($user_ident, 0xF003F, 3, 0, 0);^
$hive_HKLM = [Microsoft.Win32.Registry]::LocalMachine;^
$ntdll = Add-Type -Member '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong p, bool e, bool t, ref bool l);' -Name NtDll -PassThru;^
$lp = 0; $ntdll::RtlAdjustPrivilege(9, 1, 0, [ref]$lp);^
;^
foreach ($key_path in $key_paths_acs) {^
	$key_obj = $hive_HKLM.OpenSubKey($key_path, 2, 0x80000);^
	if (!$key_obj) { continue };^
	^
	($acl = $key_obj.GetAccessControl()).SetOwner($user_ident);^
	$key_obj.SetAccessControl($acl);^
	$acl.AddAccessRule($access_rule);^
	$key_obj.SetAccessControl($acl);^
	$key_obj.Close();^
}^
foreach ($key_path in $key_paths_del) { $hive_HKLM.DeleteSubKeyTree($key_path, 0); }^
$ntdll::RtlAdjustPrivilege(9, $lp, 0, [ref]0);^
;| powershell -noprofile - 

:_reg_HKLM_keys_access_and_delete.end
exit /b 0
