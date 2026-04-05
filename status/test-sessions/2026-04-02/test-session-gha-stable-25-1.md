# Lumina-OS Test Session

- Date: 2026-04-02
- Run Label: gha-stable-25-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-02\20260402-104704-gha-stable-25-1\lumina-os-0.1.0-dev-x86_64.iso
- Build Manifest: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\builds\2026-04-02\build-imported-20260402-104704-stable-gha-stable-25-1.md
- VM Report: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\vm-tests\2026-04-02\vm-test-gha-stable-25-1.md
- Diagnostics Bundle: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\virtualbox-shots\LuminaOS-Stable-25-Check-20260402-1047\ahmados-diagnostics-20260402-180552.tar.gz
- Diagnostics Import: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-02\20260402-110623-gha-stable-25-1\import-manifest.md

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
- Stable ISO booted successfully in a clean EFI VirtualBox VM and reached the Plasma autologin path.
- Welcome opened with the corrected preview layout and without the earlier text overlap regression.
- Diagnostics export, firstboot report, and smoke-check report were generated from inside the live session.
- The imported smoke-check report contains one false warning for the report file checking itself; this was fixed afterward in commit `fd2f9a8` and rebuild `#26`.

## Blockers
- none

## Decision Summary
- Stable mode is usable and has no hard blockers in the current VM cycle.
- Use build `#26` as the cleaned successor artifact because it keeps the same stable runtime path and removes the smoke-check false warning.
- Continue next with `login-test` validation and then a real-hardware pass on the newer artifact.

## Notes
- Diagnostics bundle path: `C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\virtualbox-shots\LuminaOS-Stable-25-Check-20260402-1047\ahmados-diagnostics-20260402-180552.tar.gz`
- Diagnostics import path: `C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-02\20260402-110623-gha-stable-25-1\import-manifest.md`
- Firstboot report confirmed the live session reached `x11` / `KDE` with `NetworkManager` and `sddm` active.
- No additional rebuild is required for runtime stability, but build `#26` is preferred because it includes the smoke-report cleanup.

