# auto-theme.ps1 - switch Windows light/dark mode by the real sun position.
# No network, no dependencies. Run with -Check to see what it would do without changing anything.
param([switch]$Check, [double]$Lat = [double]::NaN, [double]$Lon = [double]::NaN)

$cfgPath = Join-Path $env:LOCALAPPDATA 'AutoTheme\config.json'
$DarkBelow = -0.833   # sun altitude (deg) below which it's night; -0.833 = sunset/sunrise
if (Test-Path $cfgPath) {
  $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
  if ([double]::IsNaN($Lat)) { $Lat = $cfg.lat }
  if ([double]::IsNaN($Lon)) { $Lon = $cfg.lon }
  if ($null -ne $cfg.darkBelow) { $DarkBelow = $cfg.darkBelow }
}
if ([double]::IsNaN($Lat) -or [double]::IsNaN($Lon)) { throw "No location. Run install.ps1 -Lat <lat> -Lon <lon>." }

# ---- sun altitude right now (low-precision solar position, ~0.1 deg) ----
function Rad($d) { $d * [math]::PI / 180 }
function Deg($r) { $r * 180 / [math]::PI }
$d = ([datetime]::UtcNow - [datetime]::new(2000,1,1,12,0,0,[DateTimeKind]::Utc)).TotalDays
$g = Rad ((357.529 + 0.98560028 * $d) % 360)
$q = (280.459 + 0.98564736 * $d) % 360
$L = Rad (($q + 1.915 * [math]::Sin($g) + 0.020 * [math]::Sin(2 * $g)) % 360)
$e = Rad (23.439 - 0.00000036 * $d)
$ra  = [math]::Atan2([math]::Cos($e) * [math]::Sin($L), [math]::Cos($L))
$dec = [math]::Asin([math]::Sin($e) * [math]::Sin($L))
$gmst = (18.697374558 + 24.06570982441908 * $d) % 24
$ha = (Rad (($gmst * 15 + $Lon) % 360)) - $ra
$phi = Rad $Lat
$alt = Deg ([math]::Asin([math]::Sin($phi) * [math]::Sin($dec) + [math]::Cos($phi) * [math]::Cos($dec) * [math]::Cos($ha)))

$wantLight = [int]($alt -gt $DarkBelow)   # 1 = light, 0 = dark
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$cur = (Get-ItemProperty $key -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme

if ($Check) {
  "Sun altitude: {0:N2} deg -> want {1}; currently {2}" -f $alt, ('dark','light')[$wantLight], ('dark','light')[[int]$cur]
  return
}
if ($cur -eq $wantLight) { return }   # already right, do nothing

Set-ItemProperty $key -Name AppsUseLightTheme    -Value $wantLight -Type DWord
Set-ItemProperty $key -Name SystemUsesLightTheme -Value $wantLight -Type DWord

# tell running apps and the taskbar that the theme changed
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern System.IntPtr SendMessageTimeout(System.IntPtr h,uint m,System.UIntPtr w,string l,uint f,uint t,out System.UIntPtr r);'
$r = [UIntPtr]::Zero
[void][W.U]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'ImmersiveColorSet', 2, 1000, [ref]$r)
