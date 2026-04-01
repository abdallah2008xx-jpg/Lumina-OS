# Lumina-OS VM Test Report

- Date: 2026-04-01
- Run Label: gha-stable-8-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-01\20260401-132533-gha-stable-8-1\lumina-os-0.1.0-dev-x86_64.iso
- Tester: pending

## Boot Path
- [x] Boot menu appears
- [x] Selected entry starts correctly
- [x] Kernel handoff completes
- [x] Guest reaches a live X11 session, but host-side VirtualBox headless screenshots stay black

## Login Path
- [x] Stable mode reaches Plasma autologin
- [ ] Login-test mode shows the SDDM theme
- [ ] Manual login reaches Plasma when applicable

## Lumina-OS Runtime
- [x] Welcome opens for the live user
- [ ] Welcome changes apply after the app closes
- [x] Update metadata cache exists in ~/.cache/ahmados/update-center/
- [x] Firstboot report is generated at ~/.local/state/ahmados/firstboot-report.md
- [ ] Firstboot report launcher opens successfully

## Plasma Session
- [x] Wallpaper and Welcome branding render in an internal guest-side capture
- [x] Panel layout matches the selected Lumina-OS layout in an internal guest-side capture
- [ ] Color scheme looks applied correctly
- [x] Konsole opens
- [ ] Dolphin opens
- [ ] Input is responsive

## Networking And Guest Behavior
- [x] NetworkManager is active
- [x] Guest receives a working NAT address
- [ ] Browser access works if internet is available
- [ ] Guest display behavior is acceptable

## Findings
- The stable ISO boots successfully to a live X11 session for user `live`; `startplasma-x11`, `kwin_x11`, and `plasmashell` are all running.
- Host-side `VBoxManage controlvm ... screenshotpng` captures remain black even after the guest reaches Plasma, but an internal guest-side X11 capture shows the real desktop, panel, Welcome window, and Konsole correctly.
- `firstboot-report.md` is present, but it records `Welcome config: missing` and missing stamps even though `~/.config/ahmados/welcome.conf` exists later in the same session. This suggests the firstboot report is generated too early relative to Welcome persistence.
- `smoke-check-report.md` can be generated manually and passes most checks, but it reports `Session Type: unknown`, `Desktop Session: unknown`, and `Color Scheme: current unknown` despite the X11 Plasma session being active.

## Blockers
- Investigate why VirtualBox headless screenshots remain black while the guest desktop is visible from an internal X11 capture.
- Revisit firstboot timing so Welcome artifacts are present before `firstboot-report.md` is written.
- Revisit smoke-check environment detection so active Plasma session values are not reported as `unknown`.

## Notes
- Internal guest-side desktop capture saved under `build/virtualbox-shots/LuminaOS-Stable-AutoTest-20260401-1355/guest-base64-capture.png`.
- Firstboot report confirms `Session Type: x11`, `Desktop Session: KDE`, active NetworkManager, and release cache presence.
- Update Center cache files exist under `~/.cache/ahmados/update-center/` with bundled fallback metadata.
