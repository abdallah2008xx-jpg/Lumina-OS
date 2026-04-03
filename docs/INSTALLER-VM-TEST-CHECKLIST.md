# Lumina-OS Installer VM Test Checklist

Use this checklist when validating the first full installation path, not just the live ISO.

## Goal
- prove that the shipped ISO can install Lumina-OS onto a blank virtual disk
- prove that the installed system boots again after installation
- capture one installer-focused report that can be linked into release evidence

## Recommended Setup
- VM platform: `VirtualBox`
- Firmware: `UEFI`
- Graphics controller: `VBoxSVGA`
- Video memory: `128 MB`
- Blank disk target: at least `32 GB`
- ISO mode: prefer `stable` for the first full install test

## Before Starting
1. Confirm the latest `stable` ISO build exists.
2. Create a dedicated installer report with `scripts/new-install-test-report.ps1`.
3. If the build came from GitHub Actions, initialize the same report directly with `scripts/start-github-actions-install-test.ps1`.
4. Attach the ISO to a VM that has no preinstalled operating system on the target disk.
5. Keep the run label consistent with the matching build and VM evidence if possible.

## Live Session Entry
1. Boot the ISO.
2. Confirm the live Plasma session appears.
3. Confirm the `Install Lumina-OS` desktop shortcut is visible.
4. Open the launcher and confirm it starts `archinstall` in a terminal.

## Installer Flow
1. Record the target disk selection.
2. Record the partition layout used.
3. Record the filesystem used.
4. Record the user, hostname, and bootloader choices.
5. Confirm package installation completes without fatal errors.
6. Confirm bootloader installation completes.
7. Confirm `archinstall` exits with a clear success state.

## Post-Install Boot
1. Power off or reboot as instructed by the installer.
2. Detach the ISO if needed so the VM boots from disk.
3. Confirm the installed system starts from the disk.
4. Confirm the installed session reaches Plasma or the expected login path.
5. Confirm core apps such as `System Settings`, `Dolphin`, and `Konsole` open.

## Minimum Release-Relevant Checks
1. Confirm networking can be configured.
2. Confirm shutdown works.
3. Confirm reboot works.
4. Record any graphics glitches, boot issues, or missing defaults.
5. Fill blockers immediately if installation or first boot fails anywhere.

## Expected Output
- one installer report under `status/install-tests/YYYY-MM-DD/`
- optional screenshots linked from the same test notes
- any blocking issues copied into the main blocker/release workflow afterward
