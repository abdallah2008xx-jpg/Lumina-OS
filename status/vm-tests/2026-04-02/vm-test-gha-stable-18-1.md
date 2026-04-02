# Lumina-OS VM Test Report

- Date: 2026-04-02
- Run Label: gha-stable-18-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-02\20260402-060640-gha-stable-18-1\lumina-os-0.1.0-dev-x86_64.iso
- Tester: Codex local VirtualBox validation

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
- [x] Welcome opens for the live user
- [ ] Welcome changes apply after the app closes
- [ ] Update Center opens with cached release metadata
- [x] Firstboot report is generated at ~/.local/state/ahmados/firstboot-report.md
- [ ] Firstboot report launcher opens successfully

## Plasma Session
- [ ] Wallpaper is branded and renders correctly
- [ ] Panel layout matches the selected Lumina-OS layout
- [ ] Color scheme looks applied correctly
- [ ] Konsole opens
- [ ] Dolphin opens
- [ ] Input is responsive

## Networking And Guest Behavior
- [x] NetworkManager is active
- [ ] Networking can be configured
- [ ] Browser access works if internet is available
- [ ] Guest display behavior is acceptable

## Findings
- Stable ISO booted successfully into the live Plasma X11 session on VirtualBox with UEFI and autologin.
- Welcome autostarted for the `live` user, and a guest-side screenshot confirmed the right-side Session Preview text still overlaps at 1024x768.
- Imported diagnostics confirm `Session Type: x11`, `Desktop Session: KDE`, `NetworkManager active: active`, and that Welcome config plus release cache/status files are present.
- The smoke-check report still warns that the expected `AhmadOS` color scheme resolves as `current unknown`.
- Host-side `VBoxManage controlvm screenshotpng` remained unreliable for this run, so guest-side capture was used for UI inspection.

## Blockers
- none

## Notes
- Firstboot report path reviewed through the imported diagnostics bundle under `status/diagnostics/2026-04-02/20260402-062126-gha-stable-18-1/`.
- This `stable` run did not include a manual Update Center launch or a post-close Welcome apply check yet.
- Source-side fixes for the screenshot helper, session-env detection, and Welcome preview sizing are queued for the next rebuild.
