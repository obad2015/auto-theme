# auto-theme.ps1 - switch Windows light/dark mode at sunset and sunrise.
# Each run sets the theme for "now", then reschedules its own Task Scheduler task to fire
# at the next sunrise and next sunset. No network, no dependencies.
#   -Check   show sun altitude and next switch times, change nothing
param([switch]$Check, [double]$Lat = [double]::NaN, [double]$Lon = [double]::NaN)

$dir = $PSScriptRoot   # config.json and log.txt live next to this script
trap { if (-not $Check) { "{0:yyyy-MM-dd HH:mm:ss}  ERROR {1}" -f (Get-Date), $_ | Add-Content (Join-Path $dir 'log.txt') }; break }
$cfgPath = Join-Path $dir 'config.json'
$DarkBelow = -0.833   # sun altitude (deg) below which it's night; -0.833 = sunset/sunrise
if (Test-Path $cfgPath) {
  $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
  if ([double]::IsNaN($Lat)) { $Lat = $cfg.lat }
  if ([double]::IsNaN($Lon)) { $Lon = $cfg.lon }
  if ($null -ne $cfg.darkBelow) { $DarkBelow = $cfg.darkBelow }
}
if ([double]::IsNaN($Lat) -or [double]::IsNaN($Lon)) { throw "No location. Run install.ps1 -Lat <lat> -Lon <lon>." }

# ---- sun altitude at a UTC time (low-precision solar position, ~0.1 deg) ----
$J2000 = [datetime]::new(2000,1,1,12,0,0,[DateTimeKind]::Utc)
$K = [math]::PI / 180
$sinPhi = [math]::Sin($Lat * $K); $cosPhi = [math]::Cos($Lat * $K)
function Get-SunAltitude([datetime]$utc) {
  $d = ($utc - $J2000).TotalDays
  $g = ((357.529 + 0.98560028 * $d) % 360) * $K
  $L = ((280.459 + 0.98564736 * $d + 1.915 * [math]::Sin($g) + 0.020 * [math]::Sin(2 * $g)) % 360) * $K
  $e = (23.439 - 0.00000036 * $d) * $K
  $ra  = [math]::Atan2([math]::Cos($e) * [math]::Sin($L), [math]::Cos($L))
  $dec = [math]::Asin([math]::Sin($e) * [math]::Sin($L))
  $gmst = (18.697374558 + 24.06570982441908 * $d) % 24
  $ha = (($gmst * 15 + $Lon) % 360) * $K - $ra
  [math]::Asin($sinPhi * [math]::Sin($dec) + $cosPhi * [math]::Cos($dec) * [math]::Cos($ha)) / $K
}

# ---- now, and the next light/dark switches in the coming 48 h ----
$now = [datetime]::UtcNow
$alt = Get-SunAltitude $now
$wantLight = [int]($alt -gt $DarkBelow)   # 1 = light, 0 = dark
$next = @()
$prev = $wantLight
for ($m = 1; $m -le 2880 -and $next.Count -lt 2; $m++) {
  $t = $now.AddMinutes($m)
  $s = [int]((Get-SunAltitude $t) -gt $DarkBelow)
  if ($s -ne $prev) { $next += $t.AddMinutes(1).ToLocalTime(); $prev = $s }   # +1 min: fire just after the crossing
}

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$cur = (Get-ItemProperty $key -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme

if ($Check) {
  "Sun altitude: {0:N2} deg -> want {1}; currently {2}" -f $alt, ('dark','light')[$wantLight], ('dark','light')[[int]$cur]
  $next | ForEach-Object { "Next switch: {0:ddd yyyy-MM-dd HH:mm}" -f $_ }
  return
}

if ($cur -ne $wantLight) {
  Set-ItemProperty $key -Name AppsUseLightTheme    -Value $wantLight -Type DWord
  Set-ItemProperty $key -Name SystemUsesLightTheme -Value $wantLight -Type DWord
  # tell running apps and the taskbar that the theme changed
  Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern System.IntPtr SendMessageTimeout(System.IntPtr h,uint m,System.UIntPtr w,string l,uint f,uint t,out System.UIntPtr r);'
  $r = [UIntPtr]::Zero
  [void][W.U]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'ImmersiveColorSet', 2, 1000, [ref]$r)
}

# ---- reschedule: next sunrise + next sunset, plus logon and a daily midday safety net ----
$status = 'not rescheduled'
if (Get-ScheduledTask -TaskName 'AutoTheme' -ErrorAction SilentlyContinue) {
  $triggers = @((New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME),
                (New-ScheduledTaskTrigger -Daily -At '12:00'))
  $triggers += $next | ForEach-Object { New-ScheduledTaskTrigger -Once -At $_ }
  Set-ScheduledTask -TaskName 'AutoTheme' -Trigger $triggers | Out-Null
  $status = 'next: ' + (($next | ForEach-Object { $_.ToString('yyyy-MM-dd HH:mm') }) -join ', ')
}

if (Test-Path $dir) {
  "{0:yyyy-MM-dd HH:mm:ss}  alt {1,7:N2}  theme {2}  {3}" -f (Get-Date), $alt, ('dark','light')[$wantLight], $status |
    Add-Content (Join-Path $dir 'log.txt')
}
