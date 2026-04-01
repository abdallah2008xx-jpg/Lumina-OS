# Lumina-OS Desktop Layout Spec

## Goal
Ship one desktop default that feels polished immediately and remains familiar to mainstream users.

## Default Mode
`Balanced` should be the first shipping layout.

It combines:
- centered app presence
- clear running-task visibility
- one easy entry point to search and apps
- fast access to network, sound, battery, and updates

## Layout Anatomy
### Bottom panel
- location: bottom
- height: `44px` to `52px`
- visual mode: floating, with a calm translucent surface
- content alignment: centered task area, utility area on the right, launcher on the left edge of the centered cluster

### Left zone
- Lumina-OS launcher
- search-first app menu
- optional workspace overview trigger later

### Center zone
- pinned and running apps
- visible active indicator under each running app
- current app should have stronger contrast than pinned-only items

### Right zone
- system tray
- network
- sound
- battery
- language indicator
- clock and date
- quick settings entry
- update badge when relevant

## Launcher Behavior
- first action should be typing, not category browsing
- recent apps and recommended actions should appear above categories
- search results should prioritize apps, settings, files, and power actions
- Arabic and English search labels should both be considered in future implementation

## Desktop Surface
- desktop icons off by default except mounted devices if needed
- wallpaper should be visible and important to the first impression
- no unnecessary widgets on the default desktop

## Quick Settings
- open from the right utility cluster
- include Wi-Fi, Bluetooth, sound output, brightness, appearance mode, and do-not-disturb
- show battery and update summary without opening another app

## Window and Multitasking Rules
- expose virtual desktops, but do not force them
- overview should be easy to discover from the launcher or a gesture
- window chrome should stay clean and consistent with the Lumina-OS color system

## Default Pinned Apps
- Browser
- Files
- Store
- Settings
- Update Center
- Terminal

## Layout Presets
### Balanced
- centered task zone
- floating look
- default for Lumina-OS

### Classic
- left-aligned task visibility
- denser system tray
- familiar for Windows-oriented users

### Minimal
- lighter chrome
- fewer visible tray items
- best for users who prefer a cleaner desktop

## RTL and Arabic Notes
- right-side utility cluster should remain visually intentional in RTL
- icon mirroring must be reviewed for arrows, back navigation, and disclosure icons
- clock, date, and language indicators must avoid cramped mixed-script spacing

## Phase 1 KDE Implementation Notes
- use stock-stable Plasma panel behavior where possible
- avoid shell add-ons that can break on updates
- prefer theme and spacing control over plugin-heavy layout hacks
- keep one panel for the first milestone

## Success Criteria
- a new user can launch apps, connect Wi-Fi, open settings, and shut down without hunting
- the desktop looks recognizably Lumina-OS in screenshots
- the layout still feels stable in VM and low-spec environments
