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
