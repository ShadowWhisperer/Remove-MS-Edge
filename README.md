![License](https://img.shields.io/github/license/ShadowWhisperer/Remove-MS-Edge)  
<a href="https://www.buymeacoffee.com/wic8pmtmys" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Piza" height="36" width="120"></a>

```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install all Windows updates, then remove Edge. 
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
[No Terminal](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeTerm.exe) - Edge only, with no terminal. Useful for Task Scheduler  
[Edge + WebView ](https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-EdgeWeb.exe)  

<br>  

*Build From Source*  
```pyinstaller --noconsole --onefile -n Remove-Edge.exe edge.py --add-data "setup.exe;."```  

<br>

**Batch Version**

[Both](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Both.bat?raw=true) - Removes both Edge, and WebView.  
[Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge.bat?raw=true) - Removes Edge and Appx version of Edge only.  
[Edge-Appx](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge-Appx.bat?raw=true) - Remove Appx version of Edge only. Leave Webview / Chrome version alone.  

To use batch offline, download [setup.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/setup.exe?raw=true), from _Source and keep it next to the .bat

<br>

**Additional Files**  

Install [Edge](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  
Install [WebView](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)  

Fix Update issues: [Batch Script](https://raw.githubusercontent.com/ShadowWhisperer/Fix-WinUpdates/refs/heads/main/Fix%20Updates.bat)  
