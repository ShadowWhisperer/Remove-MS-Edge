<a href="https://www.buymeacoffee.com/wic8pmtmys" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Piza" height="36" width="120"></a>


**Microsoft Edge / Edge WebView uninstallers**
```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install all Windows updates, then remove Edge. 

- Uninstall WebView2 before running this, then install it again; if needed
 If Edge is installed - WebView2 installs to 'C:\Program Files (x86)\Microsoft\Edge'
 If Edge is not installed - WebView2 installs to 'C:\Program Files (x86)\Microsoft\EdgeWebView'

- .exe versions have been moved to the Retired folder, due to too many complaints of false positives          
```

[Both.bat](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Bath.bat?raw=true) Removes both Edge, and WebView.

[Edge.bat](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Edge.bat?raw=true) Removes Edge only.

[Edge-Appx.bat](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Edge-Appx.bat?raw=true) Remove Appx version of Edge only. Leave Webview / Chrome version alone.  

[Remove-NoTerm.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-NoTerm.exe?raw=true) Remove all Edges only. Completely silent, no terminal, no flags. Useful for Task Schedular.  

<br>

Removing Edge requires an internet connection to download a file.  
To make it work without internet, download [setup.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/setup.exe?raw=true), from _Source and keep it next to the .bat

Re-Install Edge: [Small DL](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)  /  [Full DL](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  

