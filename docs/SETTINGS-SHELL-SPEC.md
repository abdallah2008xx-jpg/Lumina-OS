# Lumina-OS Settings Shell Spec

## Goal
Make settings easier to scan than stock Linux control panels while staying technically realistic for KDE.

## Shell Structure
- left navigation rail for major categories
- top search row
- right content pane with card-based sections
- optional live preview area on appearance-related pages

## Recommended Categories
- Network and Internet
- Bluetooth and Devices
- Appearance
- Desktop and Dock
- Notifications and Focus
- Personalization
- Users and Login
- Apps and Defaults
- Storage
- Power and Battery
- Displays
- Sound
- Privacy and Security
- System Update
- About Lumina-OS

## Phase 1 Priorities
- Appearance
- Desktop and Dock
- Users and Login
- System Update
- About Lumina-OS

## Lumina-OS Page Style
- strong page title
- one-sentence summary below the title
- settings grouped into 2 to 4 large cards
- advanced controls kept lower on the page

## Search Behavior
- search should match page names, toggle names, and plain-language synonyms
- Arabic and English terms should both be supported later
- results should jump directly to the relevant card or page

## About Lumina-OS Page
- version
- channel
- codename
- hardware summary
- support links
- license and credits

## System Update Page
- current channel
- last checked time
- pending update summary
- release notes shortcut
- recovery guidance

## Design Constraints
- avoid nested maze-like navigation
- avoid exposing duplicate KDE paths for the same task
- keep page density moderate, not cramped

## Implementation Direction
- first phase can be a branded landing shell linking to KDE modules
- deeper unification can happen gradually after the stable ISO milestone
