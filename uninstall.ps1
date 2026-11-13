# uninstall.ps1 - remove AutoTheme. Leaves your current theme as it is.
Unregister-ScheduledTask -TaskName 'AutoTheme' -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'AutoTheme') -Recurse -Force -ErrorAction SilentlyContinue
'AutoTheme removed.'
