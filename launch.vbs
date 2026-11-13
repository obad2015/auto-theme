' Starts auto-theme.ps1 with no visible window (Task Scheduler launches this via wscript.exe).
Set fso = CreateObject("Scripting.FileSystemObject")
ps1 = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "auto-theme.ps1")
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & ps1 & """", 0, True
