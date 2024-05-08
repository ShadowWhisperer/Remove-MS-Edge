<a href="https://www.buymeacoffee.com/wic8pmtmys" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Piza" height="36" width="120"></a>


**Microsoft Edge / Edge WebView uninstallers**
```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install all Windows updates, then remove Edge. 

- Some reports of Windows Defender blocking this. Disable Defender first.  
 
Flags - Remove-Edge.exe  Remove-EdgeOnly.exe
/s  Silent      Do not print anything, or change title of window  
/e  Edge Only   Do not remove WebView  
```
<br>

**Requires WebView**  
```
- Quicken  
- Xbox App  
```

**EXE Version**  
[Remove-EdgeOnly.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-EdgeOnly.exe?raw=true) Removes edge, does not remove WebView.  
[Remove-Edge_GUI.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge_GUI.exe?raw=true) Full uninstaller with interface (option to omit WebView)  
[Remove-Edge.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge.exe?raw=true) Removes both edge, and WebView.  
[Remove-NoTerm.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-NoTerm.exe?raw=true) Remove all Edges only. Completely silent, no terminal, no flags. Useful for Task Schedular.  
<br>

**Batch Version**  (Requires internet or file from _Source)  
[Both](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Both.bat?raw=true) Removes both Edge, and WebView.  
[Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge.bat?raw=true) Removes Edge only.  
[Edge-Appx](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Batch/Edge-Appx.bat?raw=true) Remove Appx version of Edge only. Leave Webview / Chrome version alone.  
<br>

The batch version requires an internet connection to download a file.  
To make it work without internet, download [setup.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/setup.exe?raw=true), from _Source and keep it next to the .bat

Re-Install Edge: [Small DL](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)  /  [Full DL](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  
<br>

![Screenshot_GUI](https://github.com/ShadowWhisperer/Remove-MS-Edge/assets/61057625/247433f9-cb20-4cfc-9c13-bf022ecb4dda)

