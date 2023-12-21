<a href="https://www.buymeacoffee.com/wic8pmtmys" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Piza" height="36" width="120"></a>


**Microsoft Edge / Edge WebView uninstallers**
```diff
- Removing Edge may cause update failure loop. 
  Install Edge, install this update, then remove Edge. 

- Un-ininstall WebView2 before running this, then install it again; if needed
 If Edge is installed - WebView2 installs to 'C:\Program Files (x86)\Microsoft\Edge'
 If Edge is not installed - WebView2 installs to 'C:\Program Files (x86)\Microsoft\EdgeWebView'


Remove-Edge.exe  Remove-EdgeOnly.exe flags

/s  Silent      Do not print anything, or change title of window
/e  Edge Only   Do not remove WebView
```

[Remove-Edge.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge.exe?raw=true) Removes both edge, and WebView.

[Remove-EdgeOnly.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-EdgeOnly.exe?raw=true) Removes edge, does not remove WebView.  

[Remove-Edge_GUI.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge_GUI.exe?raw=true) Full uninstaller with interface (option to omit WebView)  

[Remove-NoTerm.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-NoTerm.exe?raw=true) Remove all Edges only. Completely silent, no terminal, no flags. Useful for Task Schedular.

<br>

Re-Install Edge: [Small DL](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)  /  [Full DL](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  


<img src="https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/Screenshot_GUI.PNG"/>
