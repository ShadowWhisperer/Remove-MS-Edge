@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Obtain required files (from cache or from repo with hash validation)
REM Remove Edge
REM Remove AppX
REM Remove Edge remains
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

title Edge Remover - 8/16/2025



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



set "has_net=0"
ipconfig | find "IPv" >NUL 2>&1
if %errorlevel% equ 0 set "has_net=1"

echo - Obtaining required files
call :file_obtain^
 "setup.exe"^
 "4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"^
 "https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe"^
 "file_setup"^
 %bat_log%
if %errorlevel% neq 0 echo Cannot obtain "setup.exe" (%errorinfo%) & echo. & pause & exit /b %errorlevel%

REM dll name should not be changed (see Both.bat for details)
if /i "%PROCESSOR_ARCHITECTURE%" equ "amd64" (
	call :file_obtain^
	 "System.Data.SQLite.dll"^
	 "1b3742c5bd1b3051ae396c6e62d1037565ca0cbbedb35b460f7d10a70c30376f"^
	 "https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/System.Data.SQLite.x64.dll"^
	 "file_SQLite"^
	 %bat_log%
) else (
	call :file_obtain^
	 "System.Data.SQLite.dll"^
	 "845f7cbae72cf0a09a7f8740029ea9a15cb3a51c0b883b67b6ff1fc15fb26729"^
	 "https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/System.Data.SQLite.x86.dll"^
	 "file_SQLite"^
	 %bat_log%
)
if %errorlevel% neq 0 echo Cannot obtain "System.Data.SQLite.dll" (%errorinfo%) & echo. & pause & exit /b %errorlevel%



REM query packages by pattern before Edge uninstalling
set "pkgs_pattern=*microsoftedge*"
for /f "delims=" %%p in ('powershell -noprofile -c "$pkgs='';foreach($pkg in (Get-AppxPackage -AllUsers).Where({$_.PackageFullName -like $env:pkgs_pattern})){$pkgs+=' '+[int]$pkg.NonRemovable+$pkg.PackageFullName}$pkgs.Trim()"') do (
	set "pkgs_list=%%~p"
)



REM #Uninstall
echo - Removing Edge
where "%ProgramFiles(x86)%\Microsoft\Edge\Application:*" %bat_log%
if %errorlevel% neq 0 goto uninstall.edge.done
taskkill /im MicrosoftEdgeUpdate.exe /f /t %bat_log%
start /w "" "%file_setup%" --uninstall --system-level --force-uninstall %bat_log%
:uninstall.edge.done


echo - Removing AppX
set "LOC_APPREPO_DB=%AllUsersProfile%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd"
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
set "REG32_APPX_STORE=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"

set "reg_SFT_paths_scn="
set "reg_CLS_paths_scn="
REM Registry locations for scan and remove appx keys, max length after batch vars expanding - 8167(8191 - 24; 24 - "set "reg_???_paths_scn="")
REM delimiter is \\, scan is recursive (see Both.bat for details)

REM reg_SFT_paths_scn - is only for keys located under HIVE\SOFTWARE key
REM HIVE\SOFTWARE\ part should be excluded from path
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\SecurityManager\CapAuthz\ApplicationsEx" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\AppHost\IndexedDB" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\PushNotifications\Backup" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows NT\CurrentVersion\BackgroundModel\PreInstallTasks\RequireReschedule" %bat_log%
REM reg_CLS_paths_scn - is only for keys located under HIVE\SOFTWARE\Classes key
REM HIVE\SOFTWARE\Classes\ part should be excluded from path
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\ActivatableClasses\Package" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Extensions\ContractId" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\MrtCache" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\PolicyCache" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData" %bat_log%

call :appx_unlock_and_delete %bat_log%



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
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Public') do ( call :user_lnks_remove_by_path "%%~d" %bat_log% )
del /f /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" %bat_log%
for /f "skip=2 tokens=2*" %%c in ('reg query "%REG_USERS_PATH%" /v Default') do (
	call :user_lnks_remove_by_path "%%~d" %bat_log%
	call :user_reg_cleanup .DEFAULT "%%~d" %bat_log%
)
for /f "skip=1 tokens=7 delims=\" %%k in ('reg query "%REG_USERS_PATH%" /k /f "*"') do ( call :user_cleanup_by_sid %%k %bat_log% )


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
REM delimiter is \\ (see Both.bat for details)
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


REM check script and %tmp% directories for file, check file hash, (re-)download from URL if required
REM if file successfully validated its full path will be stored to variable
REM arguments: file name, file hash, file URL and variable name in this exact order
REM return result as exit code
:file_obtain
if "%~1" equ "" goto _file_obtain.fail
if "%~2" equ "" goto _file_obtain.fail
if "%~3" equ "" goto _file_obtain.fail
if "%~4" equ "" goto _file_obtain.fail

set "on_hash_err=download"
set "file_path=%~dp0%~1"
if exist "%file_path%" goto _file_obtain.check
set "file_path=%tmp%\%~1"
if exist "%file_path%" goto _file_obtain.check

if %has_net% equ 0 goto _file_obtain.net.fail

:_file_obtain.download
set "on_hash_err=check.fail"
powershell -noprofile -c "[Net.WebClient]::new().DownloadFile('%~3', '%file_path%')"
if %errorlevel% neq 0 goto _file_obtain.download.fail
if not exist "%file_path%" goto _file_obtain.download.fail

:_file_obtain.check
powershell -noprofile -c "Import-Module Microsoft.PowerShell.Utility; exit ((Get-FileHash '%file_path%' -Algorithm SHA256).Hash.ToLower() -ne '%~2')"
if %errorlevel% neq 0 goto _file_obtain.%on_hash_err%

set "%~4=%file_path%"
exit /b 0

:_file_obtain.fail
set "errorinfo=%ISSUE_GENERIC%: generic"
exit /b %ISSUE_GENERIC%

:_file_obtain.net.fail
set "errorinfo=%ISSUE_NETWORK%: no network"
exit /b %ISSUE_NETWORK%

:_file_obtain.download.fail
set "errorinfo=%ISSUE_DOWNLOAD%: download error"
exit /b %ISSUE_DOWNLOAD%

:_file_obtain.check.fail
set "errorinfo=%ISSUE_HASH%: hash mismatch"
exit /b %ISSUE_HASH%


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
REM see Both.bat for details
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
REM see Both.bat for details


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


REM unlock and delete all packages from the list
REM list should be in pkgs_list var
REM System.Data.SQLite.dll should be ready to use
:appx_unlock_and_delete
if not defined pkgs_list goto _appx_unlock_and_delete.end
:_appx_unlock_and_delete.psl
echo function main() {^
	$pkgs = $env:pkgs_list.Split(' ', [StringSplitOptions]::RemoveEmptyEntries);^
	if ($pkgs.Count -eq 0) { return }^
	$locked_pkgs, $pkgs = $pkgs.Where({$_[0] -eq '1'}, 'Split');^
	$locked_pkgs = $locked_pkgs.ForEach({$_.Substring(1)});^
	$pkgs = $pkgs.ForEach({$_.Substring(1)});^
	^
	if ($env:reg_SFT_paths_scn) { $reg_sft_paths_scn = $env:reg_SFT_paths_scn.Trim().Split([string[]]"\\", [StringSplitOptions]::RemoveEmptyEntries) }^
	if ($env:reg_CLS_paths_scn) { $reg_cls_paths_scn = $env:reg_CLS_paths_scn.Trim().Split([string[]]"\\", [StringSplitOptions]::RemoveEmptyEntries) }^
	if ($reg_sft_paths_scn -or $reg_cls_paths_scn) {^
		$usids_exclude = @('S-1-5-18', 'S-1-5-19', 'S-1-5-20');^
		$reg_usrs_hives = (reg query "$env:REG_USERS_PATH" /k /f "*").ForEach({$_.Substring($_.LastIndexOf('\')+1)}).Where({$_.StartsWith('S-1-') -and -not $usids_exclude.Contains($_)});^
		$reg_sft_hives = ($reg_usrs_hives.ForEach({"HKU\$_\SOFTWARE\"})) + @('HKU\.DEFAULT\SOFTWARE\', 'HKLM\SOFTWARE\');^
		$reg_cls_hives = ($reg_usrs_hives.ForEach({"HKU\$_`_Classes\"})) + @('HKU\.DEFAULT\SOFTWARE\Classes\', 'HKLM\SOFTWARE\Classes\');^
	}^
	^
	if ($locked_pkgs.Count -gt 0) {^
		Add-Type -Path $env:file_SQLite;^
		$attempts = 3; $rslt = $false;^
		while ($attempts) { --$attempts; Unlock-Packages $locked_pkgs ([ref]$rslt); if ($rslt) { break }; Start-Sleep 3 }^
		if ($rslt) { $pkgs += $locked_pkgs }^
	}^
	^
	foreach ($pkg in $pkgs) {^
		Remove-AppxPackage -Package $pkg -User $env:USER_SID;^
		Remove-AppxPackage -Package $pkg -AllUsers;^
		^
		$pkg_parts = $pkg.Split('_');^
		foreach ($reg_sft_hive in $reg_sft_hives) { reg delete "$reg_sft_hive`Microsoft\UserData\UninstallTimes" /v "$($pkg_parts[0])_$($pkg_parts[4])" /f }^
		RegCleanup-Package($pkg_parts);^
		$edge_chnl_pos = $pkg_parts[0].IndexOf('.MicrosoftEdge.');^
		if ($edge_chnl_pos -ge 0) {^
			$pkg_parts[0] = $pkg_parts[0].Substring(0, $edge_chnl_pos + 14);^
			RegCleanup-Package $pkg_parts;^
		}^
		^
		reg add "$env:REG_APPX_STORE\EndOfLife\$env:USER_SID\$pkg" /f;^
		reg add "$env:REG_APPX_STORE\EndOfLife\S-1-5-18\$pkg" /f;^
		reg add "$env:REG_APPX_STORE\Deprovisioned\$pkg" /f;^
	}^
}^
function Unlock-Packages($pkgs, [ref]$rslt) {^
	$rslt.Value = $false;^
	Stop-Service StateRepository -Force;^
	^
	takeown /f "$env:LOC_APPREPO_DB";^
	takeown /f "$env:LOC_APPREPO_DB`-shm";^
	takeown /f "$env:LOC_APPREPO_DB`-wal";^
	icacls "$env:LOC_APPREPO_DB*" /grant "$env:UserName`:F" /c;^
	^
	$con = [System.Data.SQLite.SQLiteConnection]::new("Data Source=$env:LOC_APPREPO_DB");^
	$con.Open();^
	$cmd = $con.CreateCommand();^
	$cmd.CommandText = "SELECT name,sql FROM sqlite_master WHERE type='trigger' AND tbl_name='Package' AND name LIKE'%%AFTER%%' AND name LIKE'%%UPDATE%%'";^
	$res = $cmd.ExecuteReader();^
	$trgs = @{};^
	while ($res.Read()) { $trgs[$res.GetString(0)] = $res.GetString(1) } $res.Close();^
	^
	try {^
		foreach ($trg_name in $trgs.Keys) { $cmd.CommandText = "DROP TRIGGER $trg_name"; $cmd.ExecuteNonQuery() }^
		foreach ($pkg in $pkgs) {^
			$cmd.CommandText = "UPDATE Package SET IsInbox=0 WHERE PackageFullName='$pkg'"; $cmd.ExecuteNonQuery();^
			reg delete "$env:REG_APPX_STORE\InboxApplications\$pkg" /f;^
		}^
		foreach ($trg_query in $trgs.Values) { $cmd.CommandText = $trg_query; $cmd.ExecuteNonQuery() }^
		$rslt.Value = $true^
	}^
	catch { }^
	^
	$con.Close()^
}^
function RegCleanup-Package($pkg_fname_parts) {^
	$pkg_name = $pkg_fname_parts[0] + '_';^
	$pkg_pid = '_' + $pkg_fname_parts[4];^
	$reg_pkg_keys = @();^
	foreach ($reg_sft_hive in $reg_sft_hives) {^
		foreach ($reg_sft_path in $reg_sft_paths_scn) {^
			$reg_pkg_keys += (reg query "$reg_sft_hive$reg_sft_path" /s /f $pkg_name /k).Where({$_.StartsWith('HKEY_') -and $_.Contains($pkg_pid)});^
		}^
	}^
	foreach ($reg_cls_hive in $reg_cls_hives) {^
		foreach ($reg_cls_path in $reg_cls_paths_scn) {^
			$reg_pkg_keys += (reg query "$reg_cls_hive$reg_cls_path" /s /f $pkg_name /k).Where({$_.StartsWith('HKEY_') -and $_.Contains($pkg_pid)});^
		}^
	}^
	$reg_pkg_keys += (reg query "$env:REG_APPX_STORE" /s /f $pkg_name /k).Where({$_.StartsWith('HKEY_') -and $_.Contains($pkg_pid)});^
	$reg_pkg_keys += (reg query "$env:REG32_APPX_STORE" /s /f $pkg_name /k).Where({$_.StartsWith('HKEY_') -and $_.Contains($pkg_pid)});^
	^
	foreach ($reg_pkg_key in $reg_pkg_keys) { reg delete $reg_pkg_key /f }^
}^
main;^
;| powershell -noprofile - 

:_appx_unlock_and_delete.end
exit /b 0
