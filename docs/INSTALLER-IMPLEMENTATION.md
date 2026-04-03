# Lumina-OS Installer Implementation

## Current Path
- Lumina-OS now ships an `archinstall`-based installer path inside the live ISO.
- The launcher command is `/usr/local/bin/lumina-installer`.
- The legacy compatibility entrypoint remains available as `/usr/local/bin/ahmados-installer`.
- The installer is exposed in two places:
- the application menu through `lumina-installer.desktop`
- the live user's desktop through `Install Lumina-OS.desktop`

## Runtime Behavior
- The launcher opens a terminal and starts `sudo archinstall`.
- The live user already has passwordless sudo through the existing live-session setup.
- Installer logs are written by `archinstall` under `/var/log/archinstall`.

## Why This Path
- `archinstall` is an official Arch installer path and fits the current Arch-based Lumina-OS profile better than adding a heavier custom installer immediately.
- This gives Lumina-OS a real installation path now, while keeping the current ISO conservative and easier to validate.

## Remaining Work
- validate the installer end-to-end on a dedicated VM disk
- validate at least one full install on real hardware
- add Lumina-OS-specific post-install defaults if needed
- decide later whether to keep `archinstall` as the primary installer or replace it with a more branded GUI flow

## Installer Validation Workflow
- create installer-focused reports with `scripts/new-install-test-report.ps1`
- for GitHub Actions builds, initialize the same report path with `scripts/start-github-actions-install-test.ps1`
- follow the detailed runbook in `docs/INSTALLER-VM-TEST-CHECKLIST.md`
- store installer validation evidence under `status/install-tests/`
