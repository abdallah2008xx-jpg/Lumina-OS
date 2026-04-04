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
- Before `archinstall` opens, the launcher now checks that the network is ready and performs a package-database sync preflight.
- The launcher now also initializes and populates the `pacman-key` keyring automatically if the live session keyring is missing or unreadable.
- If the sync fails, the launcher stops early and shows a clearer connectivity error instead of dropping the user into a partial installer failure.
- The live image now ships a small active `mirrorlist` override so the installer is not blocked by a fully commented default mirror list.
- The launcher now tells the user to choose `Exit archinstall` after installation, not `Reboot system`, so Lumina-OS can finalize the target automatically.
- A new `lumina-finalize-install` pass now installs the expected Plasma/SDDM baseline into the target, enables the graphical services, copies Lumina-specific assets into the installed system, and applies defaults to `/etc/skel` plus any created users.
- The finalize pass now refreshes `/etc/.updated` and `/var/.updated` inside the target and queues a one-shot `ahmados-update-markers.service` pass for first boot, so Lumina-OS avoids long `ConditionNeedsUpdate` work such as `ldconfig.service` after `machine-id` and similar early writes land.
- A recovery launcher named `Finalize Installed Lumina-OS` is also available from the live session if the user already rebooted before the finalize step.
- The live user already has passwordless sudo through the existing live-session setup.
- Installer logs are written by `archinstall` under `/var/log/archinstall`.

## Why This Path
- `archinstall` is an official Arch installer path and fits the current Arch-based Lumina-OS profile better than adding a heavier custom installer immediately.
- This gives Lumina-OS a real installation path now, while keeping the current ISO conservative and easier to validate.

## Remaining Work
- validate the installer end-to-end on a dedicated VM disk
- validate at least one full install on real hardware
- decide later whether to keep `archinstall` as the primary installer or replace it with a more branded GUI flow

## Installer Validation Workflow
- create installer-focused reports with `scripts/new-install-test-report.ps1`
- for GitHub Actions builds, initialize the same report path with `scripts/start-github-actions-install-test.ps1`
- follow the detailed runbook in `docs/INSTALLER-VM-TEST-CHECKLIST.md`
- store installer validation evidence under `status/install-tests/`
