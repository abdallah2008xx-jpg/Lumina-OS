# Lumina-OS Architecture

## Product Direction
Lumina-OS should feel premium and approachable:
- premium visuals inspired by macOS
- discoverability and ease inspired by Windows
- practical Linux power underneath

## Technical Direction

### Base System
- Arch Linux base
- archiso for live ISO creation
- later: installable system profile and package repository

### Desktop Stack
- KDE Plasma
- SDDM
- X11-first for early stability in VM environments
- Wayland reconsidered after stable milestone

### Design Strategy
- Start with stock-stable components
- Add branding gradually
- Avoid custom boot/login complexity until the base is proven
- Prefer layered customization over fragile one-shot deep hacks

### Update Strategy
#### Early stage
- Source on GitHub
- Releases on GitHub Releases
- ISO downloads distributed from GitHub release assets

#### Later stage
- Optional package repository for Lumina-OS packages
- Update metadata service if needed
- GUI update center for checking release/channel information

### Release Channels
- dev
- alpha
- beta
- stable

## Non-Goals for the first milestone
- Full custom desktop shell from scratch
- Complex OTA system before stable packaging exists
- Heavy visual hacks that risk boot reliability
