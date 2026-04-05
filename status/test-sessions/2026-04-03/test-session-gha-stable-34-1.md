# Lumina-OS Test Session

- Date: 2026-04-03
- Run Label: gha-stable-34-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-03\20260403-111258-gha-stable-34-1-gha-stable-34-1\lumina-os-0.1.0-dev-x86_64.iso
- Build Manifest: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\builds\2026-04-03\build-imported-20260403-111258-stable-gha-stable-34-1-gha-stable-34-1.md
- VM Report: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\vm-tests\2026-04-03\vm-test-gha-stable-34-1.md
- Diagnostics Bundle: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\diagnostics-imports\2026-04-03\ahmados-diagnostics-20260403-181214.tar.gz
- Diagnostics Import: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\diagnostics\2026-04-03\20260403-111304-gha-stable-34-1\import-manifest.md

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
- Fresh stable build `gha-stable-34-1` booted to Plasma X11 successfully on VirtualBox without black-screen regression.
- Firstboot and smoke-check evidence were generated and imported successfully.
- `Lumina Windows Apps`, `Lumina Windows Compatibility Check`, and `Lumina Windows VM Lab` all worked on the new ISO.
- The hidden Windows Apps prep step ran automatically after login and created `windows-apps-ready.md`.

## Blockers
- none

## Decision Summary
- Continue to `login-test`; no hard blocker remains on the current stable pass.

## Notes
- Stable validation is now backed by imported diagnostics, a complete session audit, and no open blockers.
- VirtualBox correctly reports this machine as `basic-proton-only` for the Windows bridge path because nested KVM and IOMMU passthrough are not available inside the guest.
- Remaining work is no longer on stable boot quality; it is on `login-test` and the installer path.

