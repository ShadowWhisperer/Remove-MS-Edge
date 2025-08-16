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

REM Delete Desktop, StartMenu and TaskBar shortcuts; cleanup user registry
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Public') do ( call :user_lnks_remove_by_path "%%~d" )
del /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Default') do (
	call :user_lnks_remove_by_path "%%~d"
	call :user_reg_cleanup .DEFAULT "%%~d"
)
for /f "skip=1 tokens=7 delims=\" %%k in ('reg query "%REG_USERS_PATH%" /k /f "*"') do ( call :user_cleanup_by_sid %%k )


echo - Cleaning AppX remains
REM Delete remained packages
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
reg delete "HKLM\SOFTWARE\Classes\AppID\MicrosoftEdgeUpdate.exe" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Classes\AppID\{1FCBE96C-1697-43AF-9140-2897C7C69767}" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\MicrosoftEdge" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\MicrosoftEdge" /f >NUL 2>&1

set "reg_HKLM_keys_del="
REM Keys for TakeOwn+FullControl and deleting, max length after batch vars expanding - 8167(8191 - 24; 24 - "set "reg_HKLM_keys_del="")
REM delimiter is \\ (see Both.bat for details)
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\Windows\CurrentVersion\MicrosoftEdge"
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\MicrosoftEdge"
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.BCHostServer"
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.ContentProcessServer"
set "reg_HKLM_keys_del=%reg_HKLM_keys_del%\\SOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Internal.WebRuntime.F12Server"

call :reg_HKLM_keys_access_and_delete

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

REM retrieve location of user profile by user SID
REM call shortcuts removing
REM call cleanup of user registry
:user_cleanup_by_sid
if "%1" equ "S-1-5-18" goto _user_cleanup_by_sid_end
if "%1" equ "S-1-5-19" goto _user_cleanup_by_sid_end
if "%1" equ "S-1-5-20" goto _user_cleanup_by_sid_end
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%\%1" /v ProfileImagePath') do ( set "profile_path=%%~d" )
call :user_lnks_remove_by_path "%profile_path%"
call :user_reg_cleanup %1 "%profile_path%"

:_user_cleanup_by_sid_end
exit /b 0

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

exit /b 0

REM remove some registry keys
REM arguments: user SID and user profile dir path in this exact order
:user_reg_cleanup
reg query "HKU\%1" /ve >NUL 2>&1
if %errorlevel% neq 0 reg load "HKU\%1" "%~2\NTUSER.DAT" >NUL 2>&1
if %errorlevel% neq 0 goto _user_reg_cleanup_cls

reg delete "HKU\%1\SOFTWARE\Microsoft\Edge" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\EdgeUpdate" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\MicrosoftEdge" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\WOW6432Node\Microsoft\MicrosoftEdge" /f >NUL 2>&1

reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge-holographic" /f >NUL 2>&1

REM for current user require explorer restart
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesRemovedChanges" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesVersion" /f >NUL 2>&1
reg delete "HKU\%1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesChanges" /f >NUL 2>&1

:_user_reg_cleanup_cls
REM see Both.bat for details
set "cls_path=%1\SOFTWARE\Classes"
reg query "HKU\%cls_path%" /ve >NUL 2>&1
if %errorlevel% equ 0 goto _user_reg_cleanup_cls_ready

set "cls_path=%1_Classes"
reg query "HKU\%cls_path%" /ve >NUL 2>&1
REM location of user classes hive can be altered by user
if %errorlevel% neq 0 reg load "HKU\%cls_path%" "%~2\AppData\Local\Microsoft\Windows\UsrClass.dat" >NUL 2>&1
if %errorlevel% neq 0 goto _user_reg_cleanup_end

:_user_reg_cleanup_cls_ready

reg delete "HKU\%cls_path%\microsoft-edge" /f >NUL 2>&1
reg delete "HKU\%cls_path%\microsoft-edge-holographic" /f >NUL 2>&1

:_user_reg_cleanup_end
exit /b 0

REM PowerShell(psl) based functions, psl code passed via stdin
REM see Both.bat for details

REM get access and delete registry keys in HKLM hive
REM keys for TakeOwn+FullControl ONLY should be in reg_HKLM_keys_acs var
REM keys that also should be deleted - in reg_HKLM_keys_del var
REM DO NOT pass keys with values at tail
:reg_HKLM_keys_access_and_delete
if defined reg_HKLM_keys_acs goto _reg_HKLM_keys_access_and_delete_psl
if not defined reg_HKLM_keys_del goto _reg_HKLM_keys_access_and_delete_end
:_reg_HKLM_keys_access_and_delete_psl
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

:_reg_HKLM_keys_access_and_delete_end
exit /b 0
