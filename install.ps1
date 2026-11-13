# install.ps1 - install AutoTheme for the current user (no admin needed).
#   .\install.ps1 -Lat 55.68 -Lon 12.57
param(
  [Parameter(Mandatory)][double]$Lat,
  [Parameter(Mandatory)][double]$Lon,
  [double]$DarkBelow = -0.833,
  [int]$EveryMinutes = 5
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'AutoTheme'
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'auto-theme.ps1') $dir -Force
@{ lat = $Lat; lon = $Lon; darkBelow = $DarkBelow } | ConvertTo-Json | Set-Content (Join-Path $dir 'config.json') -Encoding UTF8

$script = Join-Path $dir 'auto-theme.ps1'
# conhost --headless keeps the console window from flashing
$action = New-ScheduledTaskAction -Execute 'conhost.exe' `
  -Argument "--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`""
$triggers = @(
  (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME),
  (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $EveryMinutes))
)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'AutoTheme' -Action $action -Trigger $triggers -Settings $settings `
  -Principal $principal -Description 'Switch light/dark mode at sunset and sunrise' -Force | Out-Null

Start-ScheduledTask -TaskName 'AutoTheme'
"Installed. Checks every $EveryMinutes min and at logon."
& powershell -NoProfile -ExecutionPolicy Bypass -File $script -Check
