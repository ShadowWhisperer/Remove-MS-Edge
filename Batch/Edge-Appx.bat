@echo off & setlocal

REM
REM Check permissions and elevate if required
REM Obtain required files (from cache or from repo with hash validation)
REM Remove AppX
REM Remove AppX remains
REM

set "ISSUE_GENERIC=1"
set "ISSUE_UAC=2"
set "ISSUE_NETWORK=3"
set "ISSUE_DOWNLOAD=4"
set "ISSUE_HASH=5"

REM set logging verbosity ( log_lvl.none, log_lvl.errors, log_lvl.debug )
REM also set elevated cmd mode (%ecm% var; /c or /k )
call :log_lvl.debug

title Edge Remover - 8/16/2025
echo [main_script.start] %bat_dbg%



echo [uac()] %bat_dbg%
REM Get executor SID (Win 2003(XP x64) and up)
for /f "skip=1 tokens=1,2 delims=," %%a in ('whoami /user /fo csv') do set "USER_SID=%%~b"
REM Check Admin permissions
net session >NUL 2>&1
echo err: %errorlevel%; SID: "%USER_SID%"; arg1: "%~1" %bat_dbg%
if %errorlevel% equ 0 goto uac.success
REM When UAC disabled, elevation not works
if "%USER_SID%" equ "%~1" echo Please, enable UAC and try again & echo. & pause & exit /b %ISSUE_UAC%
REM Elevate with psl (don't try go around cmd /c; see Both.bat for quotes details)
echo Start-Process -Verb RunAs """$env:COMSpec""" "%ecm% """"%~0"" ""%USER_SID%"""""|powershell -noprofile - %bat_log%
echo [uac().elevated] err: "%errorlevel%" %bat_dbg%
exit /b %errorlevel%
:uac.success
echo [uac().success] %bat_dbg%

REM Admin permissions granted, executor SID is admin SID
set "ADMIN_SID=%USER_SID%"
REM When script elevates itself, the user SID should be passed as 1st argument
if "%~1" neq "" goto uac.usid_set
REM User use Admin account or elevates script by hands
choice /c yn /n /m "Logged as Admin? [Y,N]"
REM Check for positive answer, anything else considered as No
echo answer: %errorlevel% %bat_dbg%
if %errorlevel% equ 1 goto uac.done
echo Please, run script without elevation & echo. & pause & exit /b %ISSUE_UAC%

:uac.usid_set
echo [uac().usid_set] %bat_dbg%
REM bad input here is not my fault
set "USER_SID=%~1"

:uac.done
echo [uac().done] %bat_dbg%



set "has_net=0"
ipconfig | find "IPv" >NUL 2>&1
if %errorlevel% equ 0 set "has_net=1"
echo has network: %has_net% %bat_dbg%

echo - Obtaining required files
echo obtaining files %bat_dbg%
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

echo files obtained %bat_dbg%



REM #Uninstall
echo [uninstall()] %bat_dbg%
echo - Removing AppX
echo [uninstall().appx.init] %bat_dbg%
set "LOC_APPREPO_DB=%AllUsersProfile%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd"
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
set "REG32_APPX_STORE=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"

set "pkgs_pattern=*microsoftedge*"

set "reg_SFT_paths_scn="
set "reg_CLS_paths_scn="
REM Registry locations for scan and remove appx keys, max length after batch vars expanding - 8167(8191 - 24; 24 - "set "reg_???_paths_scn="")
REM delimiter is \\, scan is recursive (see Both.bat for details)

REM reg_SFT_paths_scn - is only for keys located under HIVE\SOFTWARE key
REM HIVE\SOFTWARE\ part should be excluded from path
echo [uninstall().appx.init.reg_SFT] %bat_dbg%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\SecurityManager\CapAuthz\ApplicationsEx" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\AppHost\IndexedDB" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\PushNotifications\Backup" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore" %bat_log%
set "reg_SFT_paths_scn=%reg_SFT_paths_scn%\\Microsoft\Windows NT\CurrentVersion\BackgroundModel\PreInstallTasks\RequireReschedule" %bat_log%
REM reg_CLS_paths_scn - is only for keys located under HIVE\SOFTWARE\Classes key
REM HIVE\SOFTWARE\Classes\ part should be excluded from path
echo [uninstall().appx.init.reg_CLS] %bat_dbg%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\ActivatableClasses\Package" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Extensions\ContractId" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\MrtCache" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\PolicyCache" %bat_log%
set "reg_CLS_paths_scn=%reg_CLS_paths_scn%\\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData" %bat_log%

echo [uninstall().appx] %bat_dbg%
call :appx_unlock_and_delete %bat_log%

echo [uninstall().appx.done] %bat_dbg%

echo [uninstall().end] %bat_dbg%



REM #Cleanup
echo [cleanup()] %bat_dbg%
echo - Cleaning AppX remains
echo [cleanup().appx] %bat_dbg%
REM Delete remained packages
REM %SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*
echo [cleanup().appx.SystemApps] %bat_dbg%
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
	echo dir: "%%~d" %bat_dbg%
	takeown /f "%%~d" /r /d y %bat_dbg%
	icacls "%%~d" /grant "%UserName%:F" /t /c %bat_dbg%
	rd /s /q "%%~d" %bat_log%
)
REM %ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*
echo [cleanup().appx.WindowsApps] %bat_dbg%
for /d %%d in ("%ProgramFiles%\WindowsApps\Microsoft.MicrosoftEdge*") do (
	echo dir: "%%~d" %bat_dbg%
	takeown /f "%%~d" /r /d y %bat_dbg%
	icacls "%%~d" /grant "%UserName%:F" /t /c %bat_dbg%
	rd /s /q "%%~d" %bat_log%
)

echo [cleanup().appx.done] %bat_dbg%

echo [cleanup().end] %bat_dbg%



REM Main script end
echo - Edge removal complete
echo [main_script.end] %bat_dbg%
exit /b 0



REM =====  Functions  =====

REM labels, starts with underscore( _ ), are for internal usage and should not be called from main script
REM labels, starts with regular symbol, are public functions and can be called from main script


REM levels of logging verbosity

:log_lvl.none
REM release mode
set "bat_log=>NUL 2>&1"
set "bat_dbg=>NUL 2>&1"
set "cll_dbg=%bat_dbg%"
set "psl_dbg=*^^^>$null"
set "for_psl_dbg=*^^^^^^^>$null"
REM set "for_psl_dbg_hlpr="
REM power_hell(even 7.5) put errors to stdout if stderr not redirected
set "for_out_hlpr=2^>NUL"
REM set "for_out_get="
REM set "for_out_del="
REM all output mutes so there nothing in console
set "ecm=/c"
exit /b 0

:log_lvl.errors
REM errors only
set "bat_log=>NUL"
set "bat_dbg=>NUL 2>&1"
set "cll_dbg=%bat_dbg%"
set "psl_dbg=*^^^>$null"
set "for_psl_dbg=*^^^^^^^>$null"
REM set "for_psl_dbg_hlpr="
set "for_out_hlpr=2^>"%~dpn0_hlpr.log""
set "for_out_get=1>&2(echo [for.cmd.errors] & type "%~dpn0_hlpr.log" & echo [for.cmd.end])"
set "for_out_del=del /f /q "%~dpn0_hlpr.log" >NUL 2>&1"
set "ecm=/k"
exit /b 0

:log_lvl.debug
REM debug mode, put all output to file(except user-trageted output)
set "bat_log=>>"%~dpn0_dbg.log" 2>&1"
set "bat_dbg=>>"%~dpn0_dbg.log" 2>&1"
REM resolves issue with accessing log file from sub-routines
REM set "cll_dbg="
REM set "psl_dbg="
REM redirect debug to stderr
REM it can works without extra file but it's a quirk
set "for_psl_dbg=^^^^^^^|dbg2err"
set "for_psl_dbg_hlpr=function dbg2err^([Parameter^(ValueFromPipeline^)]$m^){process{[Console]::Error.WriteLine^($m^)}}"
set "for_out_hlpr=2^>"%~dpn0_hlpr.log""
set "for_out_get=echo [for.cmd] & type "%~dpn0_hlpr.log" & echo [for.cmd.end]"
set "for_out_del=del /f /q "%~dpn0_hlpr.log" >NUL 2>&1"
REM all output redirected to file except batch errors
set "ecm=/k"
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
echo [file_obtain()] %cll_dbg%
echo   name: "%~1" %cll_dbg%
echo   hash: "%~2" %cll_dbg%
echo   url:  "%~3" %cll_dbg%
echo   var:  "%~4" %cll_dbg%
if "%~1" equ "" goto _file_obtain.fail
if "%~2" equ "" goto _file_obtain.fail
if "%~3" equ "" goto _file_obtain.fail
if "%~4" equ "" goto _file_obtain.fail

set "on_hash_err=download"
set "file_path=%~dp0%~1"
if exist "%file_path%" goto _file_obtain.check
set "file_path=%tmp%\%~1"
if exist "%file_path%" goto _file_obtain.check

echo file not cached %cll_dbg%
if %has_net% equ 0 goto _file_obtain.net.fail

:_file_obtain.download
echo [file_obtain().download] %cll_dbg%
set "on_hash_err=check.fail"
powershell -noprofile -c "[Net.WebClient]::new().DownloadFile('%~3', '%file_path%')"
if %errorlevel% neq 0 goto _file_obtain.download.fail
if not exist "%file_path%" goto _file_obtain.download.fail

:_file_obtain.check
echo [file_obtain().check] "%file_path%"; on_hash_err: "%on_hash_err%" %cll_dbg%
powershell -noprofile -c "Import-Module Microsoft.PowerShell.Utility; exit ((Get-FileHash '%file_path%' -Algorithm SHA256).Hash.ToLower() -ne '%~2')"
if %errorlevel% neq 0 goto _file_obtain.%on_hash_err%

set "%~4=%file_path%"
echo [file_obtain().done] %cll_dbg%
exit /b 0

:_file_obtain.fail
set "errorinfo=%ISSUE_GENERIC%: generic"
echo [file_obtain().fail] %cll_dbg%
exit /b %ISSUE_GENERIC%

:_file_obtain.net.fail
set "errorinfo=%ISSUE_NETWORK%: no network"
echo [file_obtain().net.fail] %cll_dbg%
exit /b %ISSUE_NETWORK%

:_file_obtain.download.fail
set "errorinfo=%ISSUE_DOWNLOAD%: download error"
echo [file_obtain().download.fail] %cll_dbg%
exit /b %ISSUE_DOWNLOAD%

:_file_obtain.check.fail
set "errorinfo=%ISSUE_HASH%: hash mismatch"
echo [file_obtain().check.fail] %cll_dbg%
exit /b %ISSUE_HASH%



REM =====  PowerShell(psl) based complex functions  =====
REM see Both.bat for details


REM unlock and delete packages matching the pattern
REM pattern should be in pkgs_pattern var
REM System.Data.SQLite.dll should be ready to use
:appx_unlock_and_delete
echo [appx_unlock_and_delete()] %cll_dbg%
if not defined pkgs_pattern goto _appx_unlock_and_delete.end
:_appx_unlock_and_delete.psl
echo [appx_unlock_and_delete().psl] %cll_dbg%
echo function main() {^
	"query packages"%psl_dbg%;^
	$pkgs = (Get-AppxPackage -AllUsers).Where({$_.PackageFullName -like $env:pkgs_pattern});^
	if ($pkgs.Count -eq 0) { "empty packages list"%psl_dbg%; return }^
	$pkgs.PackageFullName%psl_dbg%;^
	"packages queried"%psl_dbg%;^
	$locked_pkgs, $pkgs = $pkgs.Where({$_.NonRemovable}, 'Split');^
	$locked_pkgs = [string[]]($locked_pkgs.PackageFullName);^
	$pkgs = [string[]]($pkgs.PackageFullName);^
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
		if ($rslt) { $pkgs += $locked_pkgs } else { "package(s) still locked, exclude:`n" + ($locked_pkgs -join "`n")%psl_dbg% }^
	}^
	^
	"removing"%psl_dbg%;^
	foreach ($pkg in $pkgs) {^
		"package: $pkg`nremove"%psl_dbg%;^
		Remove-AppxPackage -Package $pkg -User $env:USER_SID;^
		Remove-AppxPackage -Package $pkg -AllUsers;^
		^
		$pkg_parts = $pkg.Split('_');^
		foreach ($reg_sft_hive in $reg_sft_hives) { reg delete "$reg_sft_hive`Microsoft\UserData\UninstallTimes" /v "$($pkg_parts[0])_$($pkg_parts[4])" /f }^
		RegCleanup-Package($pkg_parts);^
		$edge_chnl_pos = $pkg_parts[0].IndexOf('.MicrosoftEdge.');^
		if ($edge_chnl_pos -ge 0) {^
			"cleanup of base package"%psl_dbg%;^
			$pkg_parts[0] = $pkg_parts[0].Substring(0, $edge_chnl_pos + 14);^
			RegCleanup-Package $pkg_parts;^
		}^
		^
		"deprovision"%psl_dbg%;^
		reg add "$env:REG_APPX_STORE\EndOfLife\$env:USER_SID\$pkg" /f;^
		reg add "$env:REG_APPX_STORE\EndOfLife\S-1-5-18\$pkg" /f;^
		reg add "$env:REG_APPX_STORE\Deprovisioned\$pkg" /f;^
		^
		"package removed"%psl_dbg%;^
	}^
}^
function Unlock-Packages($pkgs, [ref]$rslt) {^
	"[Unlock-Packages()]`nstopping services"%psl_dbg%;^
	$rslt.Value = $false;^
	Stop-Service StateRepository -Force;^
	^
	"acessing db files"%psl_dbg%;^
	takeown /f "$env:LOC_APPREPO_DB";^
	takeown /f "$env:LOC_APPREPO_DB`-shm";^
	takeown /f "$env:LOC_APPREPO_DB`-wal";^
	icacls "$env:LOC_APPREPO_DB*" /grant "$env:UserName`:F" /c;^
	^
	"unlocking"%psl_dbg%;^
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
			"package: $pkg"%psl_dbg%;^
			$cmd.CommandText = "UPDATE Package SET IsInbox=0 WHERE PackageFullName='$pkg'"; $cmd.ExecuteNonQuery();^
			reg delete "$env:REG_APPX_STORE\InboxApplications\$pkg" /f;^
		}^
		foreach ($trg_query in $trgs.Values) { $cmd.CommandText = $trg_query; $cmd.ExecuteNonQuery() }^
		"unlocked"%psl_dbg%;^
		$rslt.Value = $true^
	}^
	catch { $_%psl_dbg%; "unlocking failed"%psl_dbg% }^
	^
	$con.Close();^
	"[Unlock-Packages().end]"%psl_dbg%^
}^
function RegCleanup-Package($pkg_fname_parts) {^
	"[RegCleanup-Package()]`nregistry scan"%psl_dbg%;^
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
	"registry cleanup"%psl_dbg%;^
	foreach ($reg_pkg_key in $reg_pkg_keys) { $reg_pkg_key%psl_dbg%; reg delete $reg_pkg_key /f }^
	"[RegCleanup-Package().end]"%psl_dbg%;^
}^
main;^
;| powershell -noprofile - 

:_appx_unlock_and_delete.end
echo [appx_unlock_and_delete().end] %cll_dbg%
exit /b 0
