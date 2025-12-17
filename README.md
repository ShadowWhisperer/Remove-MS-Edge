![License](https://img.shields.io/github/license/ShadowWhisperer/Remove-MS-Edge)  

```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install all Windows updates, then remove Edge. 
```

**Requires WebView**  
```
- Eclipse IDEs
- Gmpublisher (Garry's Mod)  
- ImageGlass
- Lenovo USB Recovery Creator Tool
- Microsoft Photos App (Edit)
- PowerToys File Explorer add-ons utility
- Quicken
- Roblox
- Safing Portmaster
- Windows Mail  
- Xbox App
```

**EXE Version**  

[Edge Only](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-Edge.exe)  
[No Terminal](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeTerm.exe) - Edge only, with no terminal. Useful for Task Scheduler  
[Edge + WebView ](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeWeb.exe)  

<br>  

**Build From Source**  
```pyinstaller --onefile --noconsole -i icon.ico -n Remove-Edge.exe edge.py --add-data "setup.x64.exe;." --add-data "setup.x86.exe;."```  

<br>

**Batch Version** (Mostly by [XakerTwo](https://github.com/XakerTwo))

[Both](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Both.bat?raw=true) - Removes both Edge, and WebView.  
[Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge.bat?raw=true) - Removes Edge and Appx version of Edge only.  
[Edge-Appx](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge-Appx.bat?raw=true) - Remove Appx version of Edge only. Leave Webview / Chrome version alone.  

<br>

**Additional Files**  

Install [Edge](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  
Install [WebView](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)  

Fix Update issues: [Batch Script](https://raw.githubusercontent.com/ShadowWhisperer/Fix-WinUpdates/refs/heads/main/Fix%20Updates.bat)  
