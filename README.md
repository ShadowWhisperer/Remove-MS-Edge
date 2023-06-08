**Microsoft Edge / Edge WebView uninstallers**

```diff
! WARNING
Removal of Edge will cause update "KB5006670" (2021) to repeatedly fail/rollback.
Install Edge, run Windows Updates, then remove Edge

****************************************************************************************

Remove-Edge.exe  Remove-EdgeOnly.exe flags

/s  Silent      Do not print anything, or change title of window
/e  Edge Only   Do not remove WebView

```

[Remove-Edge.bat](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge.bat) Some versions of Edge will not work with this. (Not updated) *Chrome version only  
[Remove-Edge.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge.exe) Full uninstaller  
[Remove-EdgeOnly.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-EdgeOnly.exe) Does not remove WebView.  
[Remove-Edge_GUI.exe](https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/Remove-Edge_GUI.exe) Full uninstaller with interface (option to omit WebView)  

[_Source](https://github.com/ShadowWhisperer/Remove-MS-Edge/tree/main/_Source) contains the python script used in the executable file. [Setup.exe](https://www.virustotal.com/gui/file/4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e) was pulled from an Edge intall.  

Re-Install Edge: [Small DL](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)  /  [Full DL](https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ)  


<img src="https://github.com/ShadowWhisperer/Remove-MS-Edge/blob/main/_Source/Screenshot_GUI.PNG"/>
