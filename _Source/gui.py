#!/usr/bin/env python

#
# Check if ran with admin permissions
#  Get Admin permissions
#
# Check if Edge (Chrome) is installed - C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe
#  Run the uninstall file
#
# Check if EdgeWebView directory  *If option set
#  Run the uninstall file
#
# Delete desktop icons
# Delete start menu icons
# Delete other files
# Remove Edge Appx packages
#

import ctypes         #Check if ran as an admin / Window title
import getpass        #Take Permissions
import os             #System os paths
import sys            #Check if ran as an admin
import subprocess     #Run subprocesses
import time           #Wait 2 Seconds
import winreg         #Modify Windows Registry (Remove Edge Appx Packages)
from tkinter import * #GUI
from tkinter.scrolledtext import ScrolledText

#GUI Settings
root = Tk()
root.title("Bye Bye Edge - 5/07/2024 - ShadowWhisperer") #Windows Title
root.geometry("800x500") #Windows Size (width x height)
root.iconbitmap(sys._MEIPASS + "/icon.ico") #Icon

#Check if running as admin
if not ctypes.windll.shell32.IsUserAnAdmin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
    os._exit(0)

#Hide CMD/Powershell
def hide_console():
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.dwFlags |= subprocess.CREATE_NO_WINDOW
    return startupinfo

def remove_edge():
    output_terminal.delete("1.0", END) #Clear Terminal
    output_terminal.insert(END, "Removing Edge\n")
    root.update()  #Update Terminal

    output_terminal.tag_config("green", foreground="green")
    output_terminal.tag_config("red", foreground="red")
    src = os.path.join(sys._MEIPASS, "setup.exe")
    remove_webview = webview_var.get()

    #Edge
    if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe"):
        cmd = [src, "--uninstall", "--system-level", "--force-uninstall"]
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        # Check if pwahelper.exe remains after uninstallation
        time.sleep(3)
        if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe"):
            # Wait 3 more seconds
            time.sleep(3)
            if os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe"):
                output_terminal.insert(END, " Uninstall Failed!\n", "red")
                root.update()
            else:
                output_terminal.insert(END, " Successfully Removed\n\n", "green")
                root.update()
        else:
            output_terminal.insert(END, " Successfully Removed\n\n", "green")
            root.update()
    else:
        output_terminal.insert(END, " Not Found\n\n", "green")
        root.update()

######################################################################################################################################

    #Edge Update  *Does not always work
    if os.path.exists(r"C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"):
        command = [src, '--uninstall', '--system-level', '--force-uninstall']
        subprocess.run(command, shell=True)
        time.sleep(3)
    else:
        pass

    subprocess.run('rmdir /q /s "C:\\ProgramData\\Microsoft\\EdgeUpdate"', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

######################################################################################################################################

    #Edge WebView
    if remove_webview:
        output_terminal.insert(END, "Removing WebView\n")
        root.update()
        webview_folder_path = r"C:\Program Files (x86)\Microsoft\EdgeWebView\Application"
        if os.path.exists(webview_folder_path):
            cmd = [src, "--uninstall", "--msedgewebview", "--system-level", "--force-uninstall"]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
            process.wait()  # Wait for the uninstallation process to finish
            if os.path.exists(webview_folder_path):
                output_terminal.insert(END, " Uninstall Failed!\n", "red")
            else:
                output_terminal.insert(END, " Successfully Removed\n\n", "green")
        else:
            output_terminal.insert(END, " Not Found\n", "green")
        root.update()

######################################################################################################################################

    #Edge Appx Packages
    output_terminal.insert(END, "\nRemoving Appx Packages\n")
    root.update()
    #user_sid = subprocess.check_output(["powershell", "(Get-LocalUser -Name $env:USERNAME).SID.Value"], startupinfo=hide_console()).decode().strip()
    user_sid = subprocess.check_output(["powershell", "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value"], startupinfo=hide_console()).decode().strip()
    output = subprocess.check_output(['powershell', '-NoProfile', '-Command', 'Get-AppxPackage -AllUsers | Where-Object {$_.PackageFullName -like "*microsoftedge*"} | Select-Object -ExpandProperty PackageFullName'], startupinfo=hide_console())
    edge_apps = output.decode().strip().split('\r\n')
    if output:
        for app in edge_apps:
            winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\{user_sid}\\{app}")
            winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\S-1-5-18\\{app}")
            winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\Deprovisioned\\{app}")
            subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} 2>$null'], startupinfo=hide_console())
            subprocess.run(['powershell', '-Command', f'Remove-AppxPackage -Package {app} -AllUsers 2>$null'], startupinfo=hide_console())
            output_terminal.insert(END, f" {app}\n")
            root.update()
    else:
        pass

######################################################################################################################################

    output_terminal.insert(END, "\nRemoving Other\n")
    root.update()
    #Startup - Active Setup
    subprocess.run(['reg', 'delete', r'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}', '/f'], startupinfo=hide_console())

    #Startup Files *Wildcard
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", 0, winreg.KEY_ALL_ACCESS)
        subkeys = [winreg.EnumValue(key, i)[0] for i in range(winreg.QueryInfoKey(key)[1]) if winreg.EnumValue(key, i)[0].startswith("MicrosoftEdge")]
        for subkey_name in subkeys:
            output_terminal.insert(END, f" Key: {subkey_name}\n")
            root.update()
            winreg.DeleteValue(key, subkey_name)
    except Exception:
        pass

    # Tasks - Name
    result = subprocess.run(['schtasks', '/query', '/fo', 'csv'], capture_output=True, text=True, startupinfo=hide_console())
    tasks = result.stdout.strip().split('\n')[1:]
    microsoft_edge_tasks = [task.split(',')[0].strip('"') for task in tasks if 'MicrosoftEdge' in task]
    with open(os.devnull, 'w') as devnull:
        for task in microsoft_edge_tasks:
            output_terminal.insert(END, f" Task: {task}\n")
            root.update()
            subprocess.run(['schtasks', '/delete', '/tn', task, '/f'], check=False, stdout=devnull, stderr=devnull, startupinfo=hide_console())

    # Tasks - Files
    for tsks, dirs, files in os.walk(r"C:\Windows\System32\Tasks"):
        [os.remove(os.path.join(tasks, file)) for file in files if file.startswith("MicrosoftEdge")]

    #Edge Update Services
    service_names = ["edgeupdate", "edgeupdatem"]
    for name in service_names:
        if subprocess.run(['sc', 'delete', name], capture_output=True, text=True, startupinfo=hide_console()).returncode == 0:
            output_terminal.insert(END, f" Service: {name}\n")
            root.update()
    subprocess.run(['reg', 'delete', r'HKLM\SYSTEM\CurrentControlSet\Services\edgeupdate', '/f'], startupinfo=hide_console())
    subprocess.run(['reg', 'delete', r'HKLM\SYSTEM\CurrentControlSet\Services\edgeupdatem', '/f'], startupinfo=hide_console())

    #Program Files (x86)\Microsoft\Edge\Edge.dat
    os.remove(r"C:\Program Files (x86)\Microsoft\Edge\Edge.dat") if os.path.isfile(r"C:\Program Files (x86)\Microsoft\Edge\Edge.dat") else None

    #Desktop Icons
    for dir_name in os.listdir(r"C:\Users"):
        for link in [os.path.join(r"C:\Users", dir_name, "Desktop", name) for name in ["edge.lnk", "Microsoft Edge.lnk"]]:
            if os.path.exists(link):
                os.remove(link)

	#Start Menu Icon
    if os.path.exists("C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk"):
      os.remove("C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Microsoft Edge.lnk")
      output_terminal.insert(END, " File: C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk\n")
      root.update()
    else:
      pass

    #System32 Files
    user_name = getpass.getuser()
    for f in os.scandir("C:\\Windows\\System32"):
      if f.name.startswith("MicrosoftEdge") and f.name.endswith(".exe"):
        subprocess.run(f'takeown /f "{f.path}" > NUL 2>&1', shell=True)
        subprocess.run(f'icacls "{f.path}" /inheritance:e /grant "{user_name}:(OI)(CI)F" /T /C > NUL 2>&1', shell=True)
        output_terminal.insert(END, f" File: {f.path}\n")
        root.update()
        os.remove(f.path)

    #Remaining Edge Keys - HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge
    if not os.path.exists(r"C:\Program Files (x86)\Microsoft\Edge\Application\pwahelper.exe"):
        subprocess.run(['reg', 'delete', r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge', '/f'], stdout=subprocess.DEVNULL, startupinfo=hide_console())

    #Folders - C:\Windows\SystemApps\Microsoft.MicrosoftEdge*
    for directory, dirs, files in os.walk(r"C:\Windows\SystemApps"):
        for folder in dirs:
            if folder.startswith("Microsoft.MicrosoftEdge"):
                folder_path = os.path.join(directory, folder)
                output_terminal.insert(END, f" Folder: {folder_path}\n")
                root.update()
                subprocess.run('takeown /f "{}" /r /d y && icacls "{}" /grant administrators:F /t && rd /s /q "{}"'.format(folder_path, folder_path, folder_path), startupinfo=hide_console(), shell=True)

    #Delete extra folders
    subprocess.run('rmdir /q /s "C:\\Program Files (x86)\\Microsoft\\Temp"', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    output_terminal.insert(END, "\n\nFinished!\n", "green",)
#####################################################################################################################################
            
#Exit Button
def exit_program():
    sys.exit()


webview_var = BooleanVar()
webview_var.set(True)
checkbox = Checkbutton(root, text="Remove WebView", variable=webview_var)
checkbox.pack(pady=2)

remove_button = Button(root, text="Remove", command=remove_edge)
remove_button.pack(pady=2)

exit_button = Button(root, text="Exit", command=exit_program)
exit_button.pack(pady=2)

output_terminal = ScrolledText(root, width=800, height=30) #Terminal Size
output_terminal.pack(pady=5)

root.mainloop()
