![License](https://img.shields.io/github/license/ShadowWhisperer/Remove-MS-Edge)  
<a href="https://www.buymeacoffee.com/wic8pmtmys" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Piza" height="36" width="120"></a>

**Microsoft Edge Uninstallers**
```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install all Windows updates, then remove Edge. 
 
Flag - Remove-Edge.exe
/s  Silent      Do not print anything, or change title of window  
```
<br>

**Requires WebView**  
```
- Eclipse IDEs
- Gmpublisher (Garry's Mod)  
- ImageGlass
- Lenovo USB Recovery Creator Tool
- Microsoft Photos App (Edit)
- PowerToys File Explorer add-ons utility
- Quicken
- Windows Mail  
- Xbox App
```

**EXE Version**  

[Edge Only](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-Edge.exe)  
[No Terminal](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeTerm.exe) - Remove only edge with no terminal. Useful for Task Schedular.  
[Edge + WebView ](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeWeb.exe)  

<br>  

*Build From Source*  
```pyinstaller --noconsole --onefile -n Remove-Edge.exe edge.py --add-data "setup.exe;."```  

<br>

**Batch Version**  (Requires internet or file from _Source)  

The batch scripts have been enhanced by @XakerTwo  

[Both](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Both.bat?raw=true) - Removes both Edge, and WebView.  
[Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge.bat?raw=true) - Removes Edge and Appx version of Edge only.  
[Edge-Appx](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge-Appx.bat?raw=true) - Remove Appx version of Edge only. Leave Webview / Chrome version alone.  

<br>  

The batch version requires an internet connection to download a file.  
To make it work without internet, download [setup.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/setup.exe?raw=true), from _Source and keep it next to the .bat

Re-Install Edge: [Small DL](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)  /  [Full DL](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  
Re-Install Webview: [Link](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)  

Fix Windows Updates issues: [Bash](https://raw.githubusercontent.com/ShadowWhisperer/Fix-WinUpdates/refs/heads/main/Fix%20Updates.bat)  
<br>  
