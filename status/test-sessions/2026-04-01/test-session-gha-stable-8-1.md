# Lumina-OS Test Session

- Date: 2026-04-01
- Run Label: gha-stable-8-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-01\20260401-141411-gha-stable-8-1\lumina-os-0.1.0-dev-x86_64.iso
- Build Manifest: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\builds\2026-04-01\build-imported-20260401-141411-stable-gha-stable-8-1.md
- VM Report: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\vm-tests\2026-04-01\vm-test-gha-stable-8-1.md
- Diagnostics Bundle: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-diagnostics\2026-04-01\gha-stable-8-1-diagnostics.tar.gz
- Diagnostics Import: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-01\20260401-141416-gha-stable-8-1\import-manifest.md

## Session Objectives
- confirm the ISO boots cleanly
- confirm the expected login path for the selected mode
- confirm Welcome, Update Center, and diagnostics/export flows
- capture blockers with exact reproduction notes

## Evidence Checklist
- [x] Build manifest path recorded
- [x] VM report path recorded
- [x] Firstboot report reviewed
- [x] Diagnostics bundle exported
- [x] Diagnostics bundle imported into the repo
- [x] Findings summarized below

## Findings
- The stable ISO boots successfully to a live X11 Plasma session for user `live`.
- Guest-side X11 capture shows the real Lumina-OS desktop, panel, Welcome app, and Konsole, even though headless VirtualBox screenshots from the host remain black.
- `firstboot-report.md` is present and confirms X11/KDE plus active NetworkManager, but it reports Welcome artifacts as missing even though `welcome.conf` exists later in the same session.
- `smoke-check-report.md` can be generated and mostly passes, but it reports the current Plasma session and color scheme as `unknown`.

## Blockers
- Investigate why VirtualBox headless screenshots remain black while the guest desktop is visible from an internal X11 capture.
- Revisit firstboot timing so Welcome artifacts are present before `firstboot-report.md` is written.
- Revisit smoke-check environment detection so active Plasma session values are not reported as `unknown`.

## Decision Summary
- fix the recorded blockers before promoting this stable cycle

## Notes
- Internal guest-side desktop capture: `build/virtualbox-shots/LuminaOS-Stable-AutoTest-20260401-1355/guest-base64-capture.png`
- Diagnostics bundle imported from `build/imported-diagnostics/2026-04-01/gha-stable-8-1-diagnostics.tar.gz`
- Update metadata cache exists under `~/.cache/ahmados/update-center/` with bundled fallback status

