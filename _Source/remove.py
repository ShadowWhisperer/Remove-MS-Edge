#
# Check if ran with admin permissions
#  Get Admin permissions
#
# Check if Edge (Chrome) is installed - C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe
#  Run the uninstall file
#
# Check if EdgeWebView directory exists
#  Run the uninstall file
#
# Delete desktop icons
# Delete start menu icons
# Delete other files
# Remove Edge Appx packages
#

import ctypes      # Check if ran as an admin / Window title
import getpass     # Take Permissions
import os          # System OS paths
import sys         # Check if ran as an admin
import subprocess  # Run setup.exe file
import winreg      # Modify Windows Registry (Remove Edge Appx Packages)
import time        # Wait 2 seconds

#Set Script Title
ctypes.windll.kernel32.SetConsoleTitleW("Bye Bye Edge - 5/18/23")

#Check if running as admin
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False
if not is_admin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
    os._exit(0)

src = os.path.join(sys._MEIPASS, "setup.exe")

#Edge
if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application"):
    print("Removing Microsoft Edge")
    cmd = [src, "--uninstall", "--system-level", "--force-uninstall"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    time.sleep(2)

#EdgeWebView
if os.path.exists(r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application"):
    print("Removing WebView")
    cmd = [src, "--uninstall", "--msedgewebview", "--system-level", "--force-uninstall"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    time.sleep(2)

#Desktop Icons
for dir_name in os.listdir(r"C:\Users"):
    for link in [os.path.join(r"C:\Users", dir_name, "Desktop", name) for name in ["edge.lnk", "Microsoft Edge.lnk"]]:
        if os.path.exists(link):
            os.remove(link)

#Start Menu Icon
if os.path.exists(r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"):
    os.remove(r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk")

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

#Remove Edge Appx Packages
user_sid = subprocess.check_output(["powershell", "(Get-LocalUser -Name $env:USERNAME).SID.Value"]).decode().strip()
output = subprocess.check_output(['powershell', '-NoProfile', '-Command', 'Get-AppxPackage -AllUsers | Where-Object {$_.PackageFullName -like "*microsoftedge*"} | Select-Object -ExpandProperty PackageFullName'])
edge_apps = output.decode().strip().split('\r\n')
if output:
    for app in edge_apps:
        key_path_user = f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\{user_sid}\\{app}"
        key_path_local = f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\S-1-5-18\\{app}"
        winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, key_path_user)
        winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, key_path_local)
        subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} 2>$null'])
        subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} -AllUsers 2>$null'])
else:
    pass
