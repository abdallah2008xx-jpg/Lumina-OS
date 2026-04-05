# Lumina-OS VM Test Report

- Date: 2026-04-03
- Run Label: gha-stable-34-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-03\20260403-105816-gha-stable-34-1\lumina-os-0.1.0-dev-x86_64.iso
- Tester: Codex + local VirtualBox validation

## Boot Path
- [x] Boot menu appears
- [x] Selected entry starts correctly
- [x] Kernel handoff completes
- [x] No freeze or black screen during live boot

## Login Path
- [x] Stable mode reaches Plasma autologin
- [ ] Login-test mode shows the SDDM theme
- [ ] Manual login reaches Plasma when applicable

## Lumina-OS Runtime
- [ ] Welcome opens for the live user
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
- Live session reached Plasma X11 cleanly on the fresh `gha-stable-34-1` ISO.
- `Lumina Windows Apps`, `Lumina Windows Compatibility Check`, and `Lumina Windows VM Lab` all executed successfully from inside the guest.
- The hidden `Windows Apps` prep step wrote `windows-apps-ready.md` automatically after login.
- In VirtualBox the machine correctly classifies as `basic-proton-only`, which is expected because `/dev/kvm` and IOMMU passthrough are not exposed inside the guest.

## Blockers
- none

## Notes
- `firstboot-report.md` and `smoke-check-report.md` were both present in the guest and were imported through the diagnostics bundle.
- `smoke-check-report.md` recorded 16 passes and 0 warnings for the stable session.
- This VM pass validates the new Windows Apps surfaces on the fresh stable ISO; the next runtime target is `login-test` for SDDM/manual login coverage.
