Microsoft Edge (Chromium) uninstall script.


```diff
! WARNING
Removal of Edge will cause update "KB5006670" to continuasly fail/rollback.
Install Edge, run Windows Ppdates, and remove Edge, to fix Windows Updates

https://www.microsoft.com/en-us/edge
```

The Microsoft Edge uninstaller is located at "C:\Program Files (x86)\Microsoft\Edge\Application\VERSION-NUMBER\Installer\"
This batch script finds the version number and runs the uninstaller.
I have not seen it located under the 64bit directory, but it's there, in case it changes.

Save this script anywhere and run it as Admin.
