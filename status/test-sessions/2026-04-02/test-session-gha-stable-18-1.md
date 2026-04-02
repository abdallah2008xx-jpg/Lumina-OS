# Lumina-OS Test Session

- Date: 2026-04-02
- Run Label: gha-stable-18-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-02\20260402-062123-gha-stable-18-1\lumina-os-0.1.0-dev-x86_64.iso
- Build Manifest: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\builds\2026-04-02\build-imported-20260402-062123-stable-gha-stable-18-1.md
- VM Report: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\vm-tests\2026-04-02\vm-test-gha-stable-18-1.md
- Diagnostics Bundle: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\diagnostics-import\gha-stable-18-1-20260402-132055.tar.gz
- Diagnostics Import: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-02\20260402-062126-gha-stable-18-1\import-manifest.md

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
- Stable ISO booted into Plasma X11 and autologged into the `live` user inside VirtualBox.
- Welcome launched automatically, but the Session Preview panel still overlaps text at the 1024x768 guest resolution used for this run.
- Diagnostics export succeeded and the imported firstboot report confirms Welcome config, release cache, release status, and active NetworkManager state.
- The imported smoke-check report still warns that the expected `AhmadOS` color scheme is detected as `current unknown`.

## Blockers
- none

## Decision Summary
- Continue with a rebuild so the screenshot-helper, session-env, and Welcome preview fixes can be validated on a fresh ISO before clearing `stable`.

## Notes
- Diagnostics bundle: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\diagnostics-import\gha-stable-18-1-20260402-132055.tar.gz
- Diagnostics import: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-02\20260402-062126-gha-stable-18-1\import-manifest.md
- Runtime issues observed in this cycle are currently attention items rather than hard blockers.
- Another rebuild is required to validate the new screenshot/runtime/UI fixes against a fresh GitHub Actions ISO.

