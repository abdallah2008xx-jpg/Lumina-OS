# Lumina-OS Welcome Implementation

## Purpose
Document the real Welcome app that now ships inside the live image and writes first-run Lumina-OS choices into local config.

## Implemented Now
- QML application at `archiso-profile/airootfs/usr/share/ahmados/welcome/Main.qml`
- launcher script at `archiso-profile/airootfs/usr/local/bin/ahmados-welcome`
- desktop launcher at `archiso-profile/airootfs/usr/share/applications/ahmados-welcome.desktop`
- first-run autostart entry at `archiso-profile/airootfs/home/live/.config/autostart/ahmados-welcome.desktop`
- live-session apply bridge at `archiso-profile/airootfs/home/live/.local/bin/ahmados-apply-session-defaults`

## Runtime Path
- the app uses `qmlscene6`
- the live image includes `qt6-declarative` and `qt6-svg`
- choices are persisted through QML `Settings` into `~/.config/ahmados/welcome.conf`
- after Welcome closes, `ahmados-welcome` triggers `ahmados-apply-session-defaults --force`
- the session-apply script maps saved choices to real Plasma look-and-feel, color-scheme, and wallpaper commands

## Current Scope
- multi-step onboarding with real saved choices
- preferred Lumina-OS language selection
- light or night Lumina-OS appearance selection
- wallpaper selection from the live wallpaper pack
- Balanced, Classic, and Minimal Plasma layout choices
- preferred release-channel selection for Update Center
- user-facing preview labels for color scheme and panel style instead of raw internal IDs
- recommendation badges for the default appearance, wallpaper, layout, and release channel
- clearer finish-side summary of what Welcome will apply to the live session

## Current Limitation
- language preference is stored for Lumina-OS-owned surfaces, but it is not yet a full system locale switch
- Welcome still closes into the live session instead of offering deep task automation
- app-launch actions are still lightweight compared with a full first-run control center
- internal compatibility identifiers still remain under `ahmados` and `com.ahmados.*` even though the user-facing copy is now cleaner

## Next Logical Steps
- connect language preference to a real locale/input path
- expose more first-session actions directly from Welcome
- add validation inside a built ISO to confirm layout and wallpaper changes behave correctly after boot
- extend the saved Lumina-OS profile beyond the live session baseline
