#
#
#  Remove Both - 9.5.2024
#
#
# Check if ran with admin permissions
#  Get Admin permissions
#
# Check if Edge (Chrome) is installed - C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe
#  Run the uninstall file
#
# Remove Edge Appx packages
# Delete desktop icons
# Delete start menu icons
# Delete startup files
# Delete tasks
# Delete services
# Delete other files / folders
#

import ctypes      # Check if ran as an admin / Window title
import getpass     # Take Permissions
import os          # System OS paths
import sys         # Check if ran as an admin / silent flag
import subprocess  # Run setup.exe file
import winreg      # Modify Windows Registry (Remove Edge Appx Packages)
import time        # Wait 2 seconds

# Check if running as admin
if not ctypes.windll.shell32.IsUserAnAdmin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
    os._exit(0)


# Flags
#   /s = silent (no printing)
silent_mode = False
if len(sys.argv) > 1:
    if sys.argv[1] == '/s':
        silent_mode = True
    elif sys.argv[1] == '/?':
        print("Usage:")
        print(" /s   Silent")
        print("\n")
        sys.exit()
else:
    ctypes.windll.kernel32.SetConsoleTitleW("Bye Bye Edge - 9/6/2024 - ShadowWhisperer")


edge_only_mode = False


#Hide CMD/Powershell
def hide_console():
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.dwFlags |= subprocess.CREATE_NO_WINDOW
    return startupinfo

#Setup.exe location
src = os.path.join(sys._MEIPASS, "setup.exe")

################################################################################################################################################

#Edge
if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application"):
    if not silent_mode:
        print("Removing Microsoft Edge")
    cmd = [src, "--uninstall", "--system-level", "--force-uninstall"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    time.sleep(2)

#WebView
if not edge_only_mode:
    if os.path.exists(r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application"):
        if not silent_mode:
            print("Removing WebView")
        cmd = [src, "--uninstall", "--msedgewebview", "--system-level", "--force-uninstall"]
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        time.sleep(2)

#Remove Edge Appx Packages - Ignore 'MicrosoftEdgeDevTools'
user_sid = subprocess.check_output(["powershell", "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"], startupinfo=hide_console()).decode().strip()
output = subprocess.check_output(['powershell', '-NoProfile', '-Command', 'Get-AppxPackage -AllUsers | Where-Object {$_.PackageFullName -like "*microsoftedge*"} | Select-Object -ExpandProperty PackageFullName'], startupinfo=hide_console())
edge_apps = output.decode().strip().split('\r\n')
if output:
    for app in edge_apps:
        if 'MicrosoftEdgeDevTools' in app:
            continue
        # Create registry keys
        winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\{user_sid}\\{app}")
        winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\S-1-5-18\\{app}")
        winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\Deprovisioned\\{app}")
        # Remove the package for the current user and all users
        subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} 2>$null'], startupinfo=hide_console())
        subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} -AllUsers 2>$null'], startupinfo=hide_console())

################################################################################################################################################


#Edge Update - Leftovers
subprocess.run('rmdir /q /s "C:\\ProgramData\\Microsoft\\EdgeUpdate"', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

#Startup - Active Setup
subprocess.run(['reg', 'delete', r'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}', '/f'], startupinfo=hide_console(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
#Desktop Icons
for dir_name in os.listdir(r"C:\Users"):
    for link in [os.path.join(r"C:\Users", dir_name, "Desktop", name) for name in ["edge.lnk", "Microsoft Edge.lnk"]]:
        if os.path.exists(link):
            os.remove(link)

#Start Menu Icon
if os.path.exists(r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"):
    os.remove(r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk")

#Tasks - Name
result = subprocess.run(['schtasks', '/query', '/fo', 'csv'], capture_output=True, text=True, startupinfo=hide_console())
tasks = result.stdout.strip().split('\n')[1:]
microsoft_edge_tasks = [task.split(',')[0].strip('"') for task in tasks if 'MicrosoftEdge' in task]
with open(os.devnull, 'w') as devnull:
    for task in microsoft_edge_tasks:
        subprocess.run(['schtasks', '/delete', '/tn', task, '/f'], check=False, stdout=devnull, stderr=devnull, startupinfo=hide_console())

#Tasks - Files
for tsks, dirs, files in os.walk(r"C:\Windows\System32\Tasks"):
   [os.remove(os.path.join(tasks, file)) for file in files if file.startswith("MicrosoftEdge")]

#Edge Update Services
service_names = ["edgeupdate", "edgeupdatem"]
for name in service_names:
    if subprocess.run(['sc', 'delete', name], capture_output=True, text=True, startupinfo=hide_console()).returncode == 0:
        subprocess.run(['reg', 'delete', r'HKLM\SYSTEM\CurrentControlSet\Services\edgeupdate', '/f'], startupinfo=hide_console(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(['reg', 'delete', r'HKLM\SYSTEM\CurrentControlSet\Services\edgeupdatem', '/f'], startupinfo=hide_console(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Remaining Edge Keys - HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge
if not os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe"):
    subprocess.run(['reg', 'delete', r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge', '/f'], startupinfo=hide_console(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

#Folders - C:\Windows\SystemApps\Microsoft.MicrosoftEdge*
for directory, dirs, files in os.walk(r"C:\Windows\SystemApps"):
    for folder in dirs:
        if folder.startswith("Microsoft.MicrosoftEdge"):
            folder_path = os.path.join(directory, folder)
            with open(os.devnull, "w") as devnull:
                subprocess.run('takeown /f "{}" /r /d y && icacls "{}" /grant administrators:F /t && rd /s /q "{}"'.format(folder_path, folder_path, folder_path), startupinfo=hide_console(), shell=True, stdout=devnull, stderr=devnull)

#System32 Files
user_name = getpass.getuser()
for f in os.scandir("C:\\Windows\\System32"):
    if f.name.startswith("MicrosoftEdge") and f.name.endswith(".exe"):
        subprocess.run(f'takeown /f "{f.path}" > NUL 2>&1', shell=True)
        subprocess.run(f'icacls "{f.path}" /inheritance:e /grant "{user_name}:(OI)(CI)F" /T /C > NUL 2>&1', shell=True)
        os.remove(f.path)

#Remaining File
edge_dat_path = r"C:\Program Files (x86)\Microsoft\Edge\Edge.dat"
if os.path.exists(edge_dat_path):
    os.remove(edge_dat_path)

#Left over folders
subprocess.run('rmdir /q /s "C:\\Program Files (x86)\\Microsoft\\Temp"', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
