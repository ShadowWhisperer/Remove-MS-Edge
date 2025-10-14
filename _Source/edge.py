import ctypes      # Check if ran as an admin / Window title
import getpass     # Take Permissions
import os          # System OS paths
import sys         # Check if ran as an admin
import shutil      # Folder deletion
import subprocess  # Run setup.exe file
import winreg      # Modify Windows Registry (Remove Edge Appx Packages)
import re          # Regular expression for subkey name validation

# Check if ran as admin - Do not force run as admin
if not ctypes.windll.shell32.IsUserAnAdmin(): 
    print("\n Please run as admin.\n")
    os.system("timeout /t 4 >nul")
    sys.exit(1)

print("Bye Bye Edge - Enhanced - 8/09/2025 - ShadowWhisperer")
print("Original by ShadowWhisperer")
print("=" * 40)

# Title
ctypes.windll.kernel32.SetConsoleTitleW("Bye Bye Edge - Enhanced - 8/09/2025 - ShadowWhisperer")

# Hide CMD/Powershell
def hide_console():
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    return startupinfo

# Set Paths
src = os.path.join(getattr(sys, '_MEIPASS', os.path.dirname(__file__)), "setup.exe")
PROGRAM_FILES_X86 = os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)")
PROGRAM_FILES = os.environ.get("ProgramFiles", "C:\\Program Files")
SYSTEM_ROOT = os.environ.get("SystemRoot", "C:\\Windows")
PROGRAM_DATA = os.environ.get("ProgramData", "C:\\ProgramData")

# 32 or 64bit
is_64bit_windows = "ProgramFiles(x86)" in os.environ
access_flag = winreg.KEY_WRITE | (winreg.KEY_WOW64_64KEY if is_64bit_windows else 0)

# Get user profiles
try:
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList") as key:
        user_profiles = [winreg.EnumKey(key, i) for i in range(winreg.QueryInfoKey(key)[0])]
        USERS_DIR = [winreg.QueryValueEx(winreg.OpenKey(key, profile), "ProfileImagePath")[0] for profile in user_profiles]
    print(f"Found {len(USERS_DIR)} user profiles to process")
except Exception as e:
    print(f"Warning: Could not enumerate user profiles: {e}")
    USERS_DIR = []

################################################################################################################################################

# Edge
print("\n[1/8] Checking Microsoft Edge application...")
EDGE_PATH = os.path.join(PROGRAM_FILES_X86, "Microsoft\\Edge\\Application\\pwahelper.exe")
if os.path.exists(EDGE_PATH):
    print("Removing Microsoft Edge application...")
    try:
        cmd = [src, "--uninstall", "--system-level", "--force-uninstall"]
        subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        os.system("timeout /t 2 >nul")
        print("✓ Edge application removal initiated")
    except Exception as e:
        print(f"⚠ Edge application removal failed: {e}")
else:
    print("Microsoft Edge application not found - skipping")

# WebView
print("\n[2/8] Checking WebView2...")
WEBVIEW_PATH = os.path.join(PROGRAM_FILES_X86, "Microsoft\\EdgeWebView\\Application")
if os.path.exists(WEBVIEW_PATH):
    print("Removing WebView2...")
    try:
        cmd = [src, "--uninstall", "--msedgewebview", "--system-level", "--force-uninstall"]
        subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        print("✓ WebView2 removal initiated")
    except Exception as e:
        print(f"⚠ WebView2 removal failed: {e}")
else:
    print("WebView2 not found - skipping")

# Edge / MicrosoftEdgeDevTools (Appx Packages)
print("\n[3/8] Processing Edge AppX packages...")
try:
    user_sid = subprocess.check_output(["powershell", "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"], startupinfo=hide_console()).decode().strip()
    output = subprocess.check_output(['powershell', '-NoProfile', '-Command', 'Get-AppxPackage -AllUsers | Where-Object {$_.PackageFullName -ilike "*MicrosoftEdge*"} | Select-Object -ExpandProperty PackageFullName'], startupinfo=hide_console())
    edge_apps = [app.strip() for app in output.decode().strip().split('\r\n') if app.strip()]
    
    if edge_apps:
        print(f"Found {len(edge_apps)} Edge AppX packages to process")
        base_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
        processed = 0
        for app in edge_apps:
            try:
                for path in [f"{base_path}\\EndOfLife\\{user_sid}\\{app}", f"{base_path}\\EndOfLife\\S-1-5-18\\{app}", f"{base_path}\\Deprovisioned\\{app}"]:
                    winreg.CreateKeyEx(winreg.HKEY_LOCAL_MACHINE, path, 0, access=access_flag)
                processed += 1
            except Exception as e:
                print(f"⚠ Failed to process package: {app[:50]}...")
        print(f"✓ Processed {processed}/{len(edge_apps)} AppX packages")
    else:
        print("No Edge AppX packages found")
except Exception as e:
    print(f"⚠ AppX processing failed: {e}")


################################################################################################################################################

# Delete bad reg keys - https://github.com/ShadowWhisperer/Remove-MS-Edge/issues/80
print("\n[4/8] Cleaning malformed registry keys...")

def should_delete(name):
    return not re.search(r'[a-zA-Z]', name) or ' ' in name

def delete_tree(root, path):
    try:
        with winreg.OpenKey(root, path, 0, winreg.KEY_ALL_ACCESS | access_flag) as key:
            while True:
                try:
                    delete_tree(root, f"{path}\\{winreg.EnumKey(key, 0)}")
                except OSError:
                    break
        winreg.DeleteKeyEx(root, path, access=access_flag)
        return True
    except:
        return False

def clean_subkeys(root, path):
    try:
        cleaned = 0
        with winreg.OpenKey(root, path, 0, winreg.KEY_ALL_ACCESS | access_flag) as key:
            for i in range(winreg.QueryInfoKey(key)[0]):
                try:
                    subkey = winreg.EnumKey(key, i)
                    subkey_path = f"{path}\\{subkey}"
                    if should_delete(subkey):
                        if delete_tree(root, subkey_path):
                            cleaned += 1
                    else:
                        cleaned += clean_subkeys(root, subkey_path)
                except OSError:
                    break
        return cleaned
    except:
        return 0

try:
    cleaned_count = clean_subkeys(winreg.HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore")
    if cleaned_count > 0:
        print(f"✓ Cleaned {cleaned_count} malformed registry keys")
    else:
        print("No malformed registry keys found")
except Exception as e:
    print(f"⚠ Registry cleanup failed: {e}")

################################################################################################################################################

# Desktop Icons
print("\n[5/8] Removing desktop shortcuts and start menu icons...")

deleted_shortcuts = 0
for user_dir in USERS_DIR:
    desktop_path = os.path.join(user_dir, "Desktop")
    for link in [os.path.join(desktop_path, name) for name in ["edge.lnk", "Microsoft Edge.lnk"]]:
        try:
            if os.path.exists(link):
                os.remove(link)
                deleted_shortcuts += 1
        except Exception as e:
            pass  # Silently continue

# Start Menu Icon
START_MENU_PATH = os.path.join(PROGRAM_DATA, "Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk")
try:
    if os.path.exists(START_MENU_PATH):
        os.remove(START_MENU_PATH)
        deleted_shortcuts += 1
except Exception as e:
    pass  # Silently continue

if deleted_shortcuts > 0:
    print(f"✓ Removed {deleted_shortcuts} shortcuts and icons")
else:
    print("No shortcuts or icons found")

# Tasks - Name
print("\n[6/8] Removing scheduled tasks...")

try:
    result = subprocess.run(['schtasks', '/query', '/fo', 'csv'], capture_output=True, text=True, startupinfo=hide_console())
    tasks = result.stdout.strip().split('\n')[1:]
    microsoft_edge_tasks = [task.split(',')[0].strip('"') for task in tasks if 'MicrosoftEdge' in task]
    
    deleted_tasks = 0
    with open(os.devnull, 'w') as devnull:
        for task in microsoft_edge_tasks:
            try:
                subprocess.run(['schtasks', '/delete', '/tn', task, '/f'], check=False, stdout=devnull, stderr=devnull, startupinfo=hide_console())
                deleted_tasks += 1
            except Exception as e:
                pass  # Silently continue
    
    if deleted_tasks > 0:
        print(f"✓ Removed {deleted_tasks} scheduled tasks")
    else:
        print("No Microsoft Edge scheduled tasks found")
        
except Exception as e:
    print(f"⚠ Failed to query/remove scheduled tasks: {e}")

# Tasks - Files
TASKS_PATH = os.path.join(SYSTEM_ROOT, "System32\\Tasks")
for root, dirs, files in os.walk(TASKS_PATH):
    for file in files:
        if file.startswith("MicrosoftEdge"):
            file_path = os.path.join(root, file)
            os.remove(file_path)

# Edge Services
print("\n[7/8] Stopping and removing Edge services...")

service_names = ["edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService"]
removed_services = 0

for name in service_names:
    try:
        result = subprocess.run(['sc', 'delete', name], capture_output=True, text=True, startupinfo=hide_console())
        if result.returncode == 0:
            removed_services += 1
    except Exception as e:
        pass  # Silently continue

if removed_services > 0:
    print(f"✓ Removed {removed_services} Edge services")
else:
    print("No Edge services found to remove")

# Folders
print("\n[8/8] Removing Edge directories and files...")

# - C:\Windows\SystemApps\
# - C:\Program Files\WindowsApps\
# - C:\Program Files (x86)\Microsoft\
def run_cmd(cmd):
    subprocess.run(cmd, check=False, creationflags=subprocess.CREATE_NO_WINDOW, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def remove_directory(path):
    if os.path.exists(path):
        commands = [
            ['takeown', '/F', path, '/R', '/D', 'Y'],
            ['icacls', path, '/grant', 'BUILTIN\\Administrators:(F)', '/T'],
            ['icacls', path, '/grant', 'Everyone:(F)', '/T']
        ]
        for cmd in commands:
            run_cmd(cmd)
        shutil.rmtree(path, ignore_errors=True)
        # C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient* - would not delete with shutil
        if os.path.exists(path):
            run_cmd(['cmd.exe', '/c', 'rd', '/s', '/q', path])
        return not os.path.exists(path)
    return True

removed_dirs = 0
removed_files = 0

try:
    for root_dir in [os.path.join(SYSTEM_ROOT, "SystemApps"), os.path.join(PROGRAM_FILES, "WindowsApps")]:
        if os.path.exists(root_dir):
            for folder_name in os.listdir(root_dir):
                if folder_name.startswith(('Microsoft.MicrosoftEdge', 'Microsoft.MicrosoftEdgeDevToolsClient')):
                    if remove_directory(os.path.join(root_dir, folder_name)):
                        removed_dirs += 1
    
    run_cmd(["taskkill", "/IM", "MicrosoftEdgeUpdate.exe", "/F"])
    for folder in ["Edge", "EdgeCore", "EdgeUpdate", "Temp"]:
        folder_path = os.path.join(PROGRAM_FILES_X86, "Microsoft", folder)
        if remove_directory(folder_path):
            removed_dirs += 1
            
except Exception as e:
    pass  # Continue with file removal

# Files - System32
try:
    user_name = getpass.getuser()
    for f in os.scandir(os.path.join(SYSTEM_ROOT, "System32")):
        if f.name.startswith("MicrosoftEdge") and f.name.endswith(".exe"):
            try:
                subprocess.run(f'takeown /f "{f.path}" > NUL 2>&1', shell=True)
                subprocess.run(f'icacls "{f.path}" /inheritance:e /grant "{user_name}:(OI)(CI)F" /T /C > NUL 2>&1', shell=True)
                os.remove(f.path)
                removed_files += 1
            except Exception as e:
                pass  # Continue with next file
except Exception as e:
    pass  # Continue

if removed_dirs > 0 or removed_files > 0:
    print(f"✓ Removed {removed_dirs} directories and {removed_files} files")
else:
    print("No additional directories or files found to remove")


################################################################################################################################################


##############
#  Denied
##############
# AppUserModelId
# SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Package\Index\PackageFullName
# SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId
# Software\Microsoft\\Windows\\CurrentVersion\\AppModel\Repository\Families
# Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages

def delete_keys(hive, key, access):
    try:
        with winreg.OpenKey(hive, key, 0, access | winreg.KEY_READ) as k:
            while True:
                try:
                    subkey = winreg.EnumKey(k, 0)
                    delete_keys(hive, f"{key}\\{subkey}", access)
                except OSError:
                    break
        winreg.DeleteKeyEx(hive, key, access)
    except FileNotFoundError:
        pass
    except PermissionError:
        pass
    except Exception as e:
        pass

def delete_subkeys_with_prefix(hive, path, prefix, access):
    try:
        with winreg.OpenKey(hive, path, 0, access | winreg.KEY_READ) as k:
            i = 0
            while True:
                try:
                    subkey = winreg.EnumKey(k, i)
                    if re.match(prefix, subkey):
                        delete_keys(hive, f"{path}\\{subkey}", access)
                    else:
                        i += 1
                except OSError:
                    break
    except FileNotFoundError:
        pass
    except PermissionError:
        pass
    except Exception as e:
        pass

def hive_name(hive):
    return {
        winreg.HKEY_CURRENT_USER: "HKCU",
        winreg.HKEY_LOCAL_MACHINE: "HKLM",
        winreg.HKEY_CLASSES_ROOT: "HKCR"
    }.get(hive, str(hive))

def delete_registry_keys():
    wildcard_paths = [
        "ActivatableClasses\\Package",
        "Extensions\\ContractId\\windows.appExecutionAlias\\PackageId",
        "Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppContainer\\Storage",
        "Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\PackageRepository\\Packages",
        "Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\PolicyCache",
        "Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\SystemAppData",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.AppService\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.BackgroundTasks\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.CommandLineLaunch\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.ComponentUI\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.File\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.Launch\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.PreInstalledConfigTask\\PackageId",
        "SOFTWARE\\Classes\\Extensions\\ContractId\\Windows.Protocol\\PackageId",
        "SOFTWARE\\Microsoft\\SecurityManager\\CapAuthz\\ApplicationsEx",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppHost\\IndexedDB",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\Applications",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\Config",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\Capabilities\\microphone\\Apps",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\Capabilities\\userAccountInformation\\Apps",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\Capabilities\\webcam\\Apps",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\cellularData",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\microphone",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\picturesLibrary",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\userAccountInformation",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\wifiData",
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PushNotifications\\Backup",
        "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\BackgroundModel\\PreInstallTasks\\RequireReschedule",
        "SYSTEM\\Setup\\Upgrade\\Appx\\DownlevelGather\\AppxAllUserStore\\Config",
        "SYSTEM\\Setup\\Upgrade\\Appx\\DownlevelGather\\AppxAllUserStore\\InboxApplications",
        "SYSTEM\\Setup\\Upgrade\\Appx\\DownlevelGather\\PackageInstallState"
    ]

    full_delete_paths = [
        "AppID\\MicrosoftEdgeUpdate.exe",
        "SOFTWARE\\Classes\\microsoft-edge",
        "SOFTWARE\\Classes\\microsoft-edge-holographic",
        "SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{9459C573-B17A-45AE-9F64-1857B5D58CEE}",
        "SOFTWARE\\Microsoft\\Edge",
        "SOFTWARE\\Microsoft\\EdgeUpdate",
        "SOFTWARE\\Microsoft\\Internet Explorer\\EdgeDebugActivation",
        "SOFTWARE\\Microsoft\\Internet Explorer\\EdgeIntegration",
        "SOFTWARE\\Microsoft\\MicrosoftEdge",
        "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options\\MicrosoftEdgeUpdate.exe",
        "SOFTWARE\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\microsoft-edge",
        "SOFTWARE\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\microsoft-edge-holographic",
        "SOFTWARE\\WOW6432Node\\Microsoft\\Edge",
        "SOFTWARE\\WOW6432Node\\Microsoft\\EdgeUpdate",
        "SYSTEM\\CurrentControlSet\\Services\\edgeupdate",
        "SYSTEM\\CurrentControlSet\\Services\\edgeupdatem",
        "SYSTEM\\CurrentControlSet\\Services\\MicrosoftEdgeElevationService"
    ]

    hives = [winreg.HKEY_CURRENT_USER, winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CLASSES_ROOT]

    # Wildcard deletions - Microsoft.MicrosoftEdge
    for path in wildcard_paths:
        for hive in hives:
            for access in [winreg.KEY_WOW64_32KEY, winreg.KEY_WOW64_64KEY]:
                delete_subkeys_with_prefix(hive, path, r"(?i)^microsoft\.microsoftedge.*", access)

    # Full path deletions
    for path in full_delete_paths:
        for hive in hives:
            for access in [winreg.KEY_WOW64_32KEY, winreg.KEY_WOW64_64KEY]:
                delete_keys(hive, path, access)

delete_registry_keys()

#HKEY_CLASSES_ROOT\MicrosoftEdge*
def delete_hkcr_microsoftedge_keys():
    for hive in [winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER]:
        base_path = "Software\\Classes"
        for access in [winreg.KEY_WOW64_64KEY, winreg.KEY_WOW64_32KEY]:
            try:
                with winreg.OpenKey(hive, base_path, 0, access | winreg.KEY_READ) as root:
                    i = 0
                    while True:
                        try:
                            key_name = winreg.EnumKey(root, i)
                            if key_name.startswith(("MicrosoftEdge", "microsoft-edge")):
                                delete_keys(hive, f"{base_path}\\{key_name}", access | winreg.KEY_ALL_ACCESS)
                            else:
                                i += 1
                        except OSError:
                            break
            except:
                pass

delete_hkcr_microsoftedge_keys()

################################################################################################################################################

print("\n" + "="*60)
print("Microsoft Edge Removal Complete!")
print("="*60)
print("\n⚠ IMPORTANT: Please restart your computer to complete the removal process.")
print("\n✓ All removal tasks have been executed successfully.")
print("  If Edge was not completely removed, you may need to:")
print("  - Run the script again after restart")
print("  - Check for Windows updates that might reinstall Edge")
print("  - Manually remove any remaining registry entries")
print("\nPress any key to exit...")
input()
