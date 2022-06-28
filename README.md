Microsoft Edge (Chromium) / Edge WebView uninstall script.


```diff
! WARNING
Removal of Edge will cause update "KB5006670" to repeatedly fail/rollback.
Install Edge, run Windows Updates, and remove Edge, to fix Windows Updates

https://www.microsoft.com/en-us/edge
```

The Microsoft Edge uninstaller is located at "C:\Program Files (x86)\Microsoft\Edge\Application\VERSION-NUMBER\Installer\"  
This batch script finds the version number and runs the uninstaller.  

Save this script anywhere and run it as Admin.
