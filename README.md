# AutoTheme

Switches Windows 11 between light and dark mode at **sunset and sunrise**, the same times Night light uses on its "Sunset to sunrise" schedule.

- No install of third-party software, no network access, no admin rights.
- About 50 lines of PowerShell: it works out where the sun is from your coordinates and the clock, then sets the two standard theme values (`AppsUseLightTheme`, `SystemUsesLightTheme`).
- Task Scheduler has no sunset trigger, so the task schedules itself: each run sets the theme, then works out the next sunrise and sunset and sets its own triggers to those exact times. It also runs at logon and daily at 12:00 as a safety net. If the PC was asleep at sunset, the task runs as soon as it wakes. No window pops up.
- Each run adds one line to `%USERPROFILE%\.autotheme\log.txt`.

## Install

```powershell
git clone https://github.com/obad2015/auto-theme
cd auto-theme
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Lat 55.68 -Lon 12.57
```

Use your own latitude/longitude. Your location is only stored locally in `%USERPROFILE%\.autotheme\config.json`.

Option: `-DarkBelow -6` switches at civil dusk instead of sunset.

## Check / uninstall

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.autotheme\auto-theme.ps1" -Check
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

For apps to follow along, set their theme to "System".

## License

MIT
