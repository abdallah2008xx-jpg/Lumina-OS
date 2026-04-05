# Lumina-OS VM Test Report

- Date: 2026-04-04
- Run Label: gha-login-test-35-1
- Mode: login-test
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: not-recorded-yet
- Tester: pending

## Boot Path
- [ ] Boot menu appears
- [ ] Selected entry starts correctly
- [ ] Kernel handoff completes
- [ ] No freeze or black screen during live boot

## Login Path
- [ ] Stable mode reaches Plasma autologin
- [ ] Login-test mode shows the SDDM theme
- [ ] Manual login reaches Plasma when applicable

## Lumina-OS Runtime
- [ ] Welcome opens for the live user
- [ ] Welcome changes apply after the app closes
- [ ] Update Center opens with cached release metadata
- [ ] Firstboot report is generated at ~/.local/state/ahmados/firstboot-report.md
- [ ] Firstboot report launcher opens successfully

## Plasma Session
- [ ] Wallpaper is branded and renders correctly
- [ ] Panel layout matches the selected Lumina-OS layout
- [ ] Color scheme looks applied correctly
- [ ] Konsole opens
- [ ] Dolphin opens
- [ ] Input is responsive

## Networking And Guest Behavior
- [ ] NetworkManager is active
- [ ] Networking can be configured
- [ ] Browser access works if internet is available
- [ ] Guest display behavior is acceptable
- [ ] No oversized desktop or scrollbars are visible in the VM window
- [ ] Display resize or fallback behavior is recorded when using VirtualBox

## Findings
- none yet

## Blockers
- none yet

## Notes
- add firstboot-report observations here
- add SDDM/theme observations here
- add regression notes here
