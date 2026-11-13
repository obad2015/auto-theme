# uninstall.ps1 - remove AutoTheme. Leaves your current theme as it is.
param([string]$InstallDir = (Join-Path $env:USERPROFILE '.autotheme'))
Unregister-ScheduledTask -TaskName 'AutoTheme' -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
'AutoTheme removed.'
