# Lumina-OS Install Test Report

- Date: 2026-04-04
- Run Label: gha-stable-37-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-04\20260404-073254-gha-stable-37-1\lumina-os-0.1.0-dev-x86_64.iso
- Install Target: blank-vm-disk
- Installer Launcher: Install Lumina-OS.desktop
- Installer Command: /usr/local/bin/lumina-installer
- Tester: pending
- Overall Status: in-progress

## Pre-Install Checks
- [x] ISO boots on the chosen blank-disk VM
- [x] Desktop reaches Plasma successfully before installation
- [x] Install Lumina-OS launcher is visible on the desktop
- [ ] Installer terminal opens without launcher errors

## Installer Flow
- [ ] archinstall starts successfully
- [ ] Target disk is detected correctly
- [ ] Partitioning completes without installer errors
- [ ] Base package installation completes
- [ ] Bootloader installation completes
- [ ] Installer reaches a clean completion message

## First Boot After Install
- [ ] VM reboots from the installed disk instead of the ISO
- [ ] Installed system reaches the login/session path successfully
- [ ] Plasma starts on the installed system
- [ ] No immediate black screen or boot loop appears

## Installed Runtime Checks
- [ ] Networking is available or configurable
- [ ] System Settings opens
- [ ] Dolphin opens
- [ ] Konsole opens
- [ ] Wallpaper and core Lumina branding appear correctly
- [ ] Shutdown and reboot work from the installed session

## Findings
- Stable build `gha-stable-37-1` booted successfully on a blank-disk VirtualBox VM with a new 32 GB VDI attached.
- Plasma reached the desktop and exposed the `Install Lumina-OS` launcher as expected.
- The new installer preflight build is present in this ISO, but VirtualBox guest-control desktop readiness did not come up in this session, so automated in-guest command execution is currently blocked.

## Blockers
- VirtualBox guest-control does not reach the desktop run level on this install-test VM yet, which blocks automated launcher execution from the host side.

## Notes
- VM: `LuminaOS-LoginTest-34-Check-20260403-1119`
- Disk: `LuminaOS-InstallTest-32GB.vdi`
- ISO: `C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-04\20260404-073254-gha-stable-37-1\lumina-os-0.1.0-dev-x86_64.iso`
- Screenshot evidence: `build/virtualbox-shots/LuminaOS-LoginTest-34-Check-20260403-1119/stable37-installtest-boot.png`
