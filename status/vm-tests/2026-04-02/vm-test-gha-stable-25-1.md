# Lumina-OS VM Test Report

- Date: 2026-04-02
- Run Label: gha-stable-25-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-02\20260402-104704-gha-stable-25-1\lumina-os-0.1.0-dev-x86_64.iso
- Tester: Codex

## Boot Path
- [ ] Boot menu appears
- [x] Selected entry starts correctly
- [x] Kernel handoff completes
- [x] No freeze or black screen during live boot

## Login Path
- [x] Stable mode reaches Plasma autologin
- [ ] Login-test mode shows the SDDM theme
- [ ] Manual login reaches Plasma when applicable

## Lumina-OS Runtime
- [x] Welcome opens for the live user
- [ ] Welcome changes apply after the app closes
- [ ] Update Center opens with cached release metadata
- [x] Firstboot report is generated at ~/.local/state/ahmados/firstboot-report.md
- [ ] Firstboot report launcher opens successfully

## Plasma Session
- [x] Wallpaper is branded and renders correctly
- [x] Panel layout matches the selected Lumina-OS layout
- [x] Color scheme looks applied correctly
- [ ] Konsole opens
- [ ] Dolphin opens
- [x] Input is responsive

## Networking And Guest Behavior
- [x] NetworkManager is active
- [ ] Networking can be configured
- [ ] Browser access works if internet is available
- [x] Guest display behavior is acceptable

## Findings
- Welcome rendered with the corrected preview-side layout and no text overlap.
- The centered balanced panel loaded correctly with the conservative launcher defaults.
- Diagnostics export and smoke checks completed from inside the live session.

## Blockers
- none

## Notes
- Firstboot report recorded `x11` / `KDE` and showed `NetworkManager` plus `sddm` active in the live session.
- VirtualBox display was acceptable with `VBoxSVGA` and EFI on this clean VM.
- Imported smoke report had one self-check warning that was fixed later in commit `fd2f9a8`; no hard runtime blocker was observed in this VM pass.
