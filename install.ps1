# install.ps1 - install AutoTheme for the current user (no admin needed).
#   .\install.ps1 -Lat 55.68 -Lon 12.57
param(
  [Parameter(Mandatory)][double]$Lat,
  [Parameter(Mandatory)][double]$Lon,
  [double]$DarkBelow = -0.833,
  [string]$InstallDir = (Join-Path $env:USERPROFILE '.autotheme')
)
$ErrorActionPreference = 'Stop'
$dir = $InstallDir
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'auto-theme.ps1'), (Join-Path $PSScriptRoot 'launch.vbs') $dir -Force
@{ lat = $Lat; lon = $Lon; darkBelow = $DarkBelow } | ConvertTo-Json | Set-Content (Join-Path $dir 'config.json') -Encoding UTF8

$script = Join-Path $dir 'auto-theme.ps1'
# launch.vbs runs the script with no console window flashing
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "//B //NoLogo `"$(Join-Path $dir 'launch.vbs')`""
$triggers = @(
  (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME),
  (New-ScheduledTaskTrigger -Daily -At '12:00')
)   # the first run adds the exact sunrise/sunset triggers itself
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'AutoTheme' -Action $action -Trigger $triggers -Settings $settings `
  -Principal $principal -Description 'Switch light/dark mode at sunset and sunrise' -Force | Out-Null

Start-ScheduledTask -TaskName 'AutoTheme'
Start-Sleep -Seconds 5
"Installed. Runs at sunrise, sunset, logon and daily at 12:00."
& powershell -NoProfile -ExecutionPolicy Bypass -File $script -Check
Get-Content (Join-Path $dir 'log.txt') -Tail 1 -ErrorAction SilentlyContinue
