# AutoTheme

Switches Windows 11 between light and dark mode at **sunset and sunrise**, the same times Night light uses on its "Sunset to sunrise" schedule.

- No install of third-party software, no network access, no admin rights.
- About 50 lines of PowerShell: it works out where the sun is from your coordinates and the clock, then sets the two standard theme values (`AppsUseLightTheme`, `SystemUsesLightTheme`).
- A per-user scheduled task runs it every 5 minutes and at logon. It only writes when the theme needs to change, and no window pops up.

## Install

```powershell
git clone https://github.com/obad2015/auto-theme
cd auto-theme
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Lat 55.68 -Lon 12.57
```

Use your own latitude/longitude. Your location is only stored locally in `%LOCALAPPDATA%\AutoTheme\config.json`.

Options: `-DarkBelow -6` switches at civil dusk instead of sunset. `-EveryMinutes 10` checks less often.

## Check / uninstall

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\AutoTheme\auto-theme.ps1" -Check
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

For apps to follow along, set their theme to "System".

## License

MIT
