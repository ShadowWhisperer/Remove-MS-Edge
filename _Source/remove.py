#
# Check if ran with admin permissions
#  Ask/get admin permissions
#
# Checks if Chrome based version of Edge is installed / Finds the correct directory
#  Checks if "setup.exe" exists
#   Replace the uninstaller "setup.exe" for Edge, with a working/older version
#    Wait 2 seconds to be sure it finished copying
#     Runs the uninstall command
#
# Searches for EdgeWebView directory
#  Checks if "setup.exe" exists
#   Runs the uninstall command
#
# Delete desktop icons
# Delete startmenu icons
# Delete other files
# Add Edge Apps to "EndOfLife" in Registry
#

import ctypes      #Check if ran as an admin / Get User SID / Window title
import getpass     #Take Permissions
import os          #System os paths
import sys         #Check if ran as an admin
import subprocess  #Run setup.exe file
import time        #Sleep command
import winreg      #Windows registry

# Set Script Title
ctypes.windll.kernel32.SetConsoleTitleW("Remove MS Edge (Chrome Version)")

# Run script as admin
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, "", None, 1)
else:
    src = os.path.join(sys._MEIPASS, "setup.exe")


    # Edge
    if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application"):
        for dir in os.listdir(r"C:\Program Files (x86)\Microsoft\Edge\Application"):
            installer_dir = os.path.join(r"C:\Program Files (x86)\Microsoft\Edge\Application", dir, "Installer")
            if os.path.exists(os.path.join(installer_dir, "setup.exe")):
                print("Removing Microsoft Edge")
                os.chdir(installer_dir)
                os.replace(src, "setup.exe")
                time.sleep(2)
                subprocess.run(["setup.exe", "--uninstall", "--system-level", "--force-uninstall"],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

	# EdgeWebView
    if os.path.exists(r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application"):
        for dir in os.listdir(r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application"):
            installer_dir = os.path.join(r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application", dir, "Installer")
            if os.path.exists(os.path.join(installer_dir, "setup.exe")):
                print("Removing WebView")
                os.chdir(installer_dir)
                subprocess.run(["setup.exe", "--uninstall", "--msedgewebview", "--system-level", "--force-uninstall"],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    #Desktop Icons
    for dir_name in os.listdir(r"C:\Users"):
        for link in [os.path.join(r"C:\Users", dir_name, "Desktop", name) for name in ["edge.lnk", "Microsoft Edge.lnk"]]:
            if os.path.exists(link):
                os.remove(link)

	#Start Menu Icon
    if os.path.exists("C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk"):
      os.remove("C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk")
    else:
      pass

    #Other Files
    user_name = getpass.getuser()
    for f in os.scandir("C:\\Windows\\System32"):
      if f.name.startswith("MicrosoftEdge") and f.name.endswith(".exe"):
        subprocess.run(f'takeown /f "{f.path}" > NUL 2>&1', shell=True)
        subprocess.run(f'icacls "{f.path}" /inheritance:e /grant "{user_name}:(OI)(CI)F" /T /C > NUL 2>&1', shell=True)
        os.remove(f.path)



##
## Disable Edge app in registry   HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\   
##
    # Current sser's SID
    def get_current_user_sid():
        sid = ctypes.c_char_p()
        size = ctypes.c_int()
        ctypes.windll.advapi32.GetUserNameA(None, ctypes.byref(size))
        name = ctypes.create_string_buffer(size.value + 1)
        ctypes.windll.advapi32.GetUserNameA(name, ctypes.byref(size))
        user_name = name.value.decode("utf-8")
        command = f'wmic useraccount where name="{user_name}" get sid'
        result = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout.decode('utf-8')
        return result.strip().split("\n")[1]

    #Find installed Edge apps
    def find_edge_apps():
        command = 'Get-AppxPackage | Where-Object {$_.Name -like "*microsoftedge*"} | Select-Object PackageFullName'
        result = subprocess.run(['powershell.exe', command], stdout=subprocess.PIPE).stdout.decode('utf-8')
        apps = result.strip().split("\n")[1:]
        return [app.strip() for app in apps if "Edge" in app]

    #Build the registry key
    def add_registry_key(sid, package):
        key = winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife")
        subkey = winreg.CreateKey(key, sid)
        winreg.SetValueEx(subkey, package, 0, winreg.REG_SZ, "")
        winreg.CloseKey(subkey)
        winreg.CloseKey(key)

    #Add the key(s)
    sid = get_current_user_sid().strip()
    apps = find_edge_apps()
    for app in apps:
        full_key = f"HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\{sid}\\{app}"
        add_registry_key(sid, app)
