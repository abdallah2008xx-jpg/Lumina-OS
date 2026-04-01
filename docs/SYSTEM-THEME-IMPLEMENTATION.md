# AhmadOS System Theme Implementation

## Purpose
Document the real theme assets that now ship inside the live system image.

## Implemented Now
- custom SDDM theme under `archiso-profile/airootfs/usr/share/sddm/themes/ahmados/`
- custom AhmadOS color scheme under `archiso-profile/airootfs/usr/share/color-schemes/AhmadOS.colors`
- custom AhmadOS Plasma look-and-feel package under `archiso-profile/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop/`
- branded wallpaper assets under `archiso-profile/airootfs/usr/share/ahmados/wallpapers/`
- live-session autostart hook that applies AhmadOS defaults for the `live` user

## Plasma Application Path
The live session uses:
- `~/.config/kdeglobals` to point to the AhmadOS color scheme and look-and-feel package
- `~/.config/autostart/ahmados-session-defaults.desktop` to run a one-time defaults script
- `~/.local/bin/ahmados-apply-session-defaults` to apply:
  - look and feel
  - color scheme
  - wallpaper

## SDDM Application Path
- `/etc/sddm.conf.d/theme.conf` now points to `Current=ahmados`
- the theme itself lives in `/usr/share/sddm/themes/ahmados/`

## Current Limitation
- the live ISO still autologins for stability, so the SDDM theme is implemented but may not be visible unless autologin is disabled for testing
- the Plasma layout is implemented as a real look-and-feel package, but a full AhmadOS Welcome app and Settings shell are still future work

## Next Logical Steps
- turn the SDDM theme into a fully packaged release asset with previews
- implement the Welcome flow as a real Qt/QML app
- replace more stock KDE entry surfaces with AhmadOS-native pages over time
