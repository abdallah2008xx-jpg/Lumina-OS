# Lumina-OS Install Test Report

- Date: 2026-04-03
- Run Label: gha-stable-27-1
- Mode: stable
- VM Type: VirtualBox
- Firmware: UEFI
- ISO Path: C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\imported-iso\2026-04-03\20260403-094831-gha-stable-27-1\lumina-os-0.1.0-dev-x86_64.iso
- Install Target: blank-vm-disk
- Installer Launcher: Install Lumina-OS.desktop
- Installer Command: /usr/local/bin/lumina-installer
- Tester: pending
- Overall Status: in-progress

## Pre-Install Checks
- [ ] ISO boots on the chosen blank-disk VM
- [ ] Desktop reaches Plasma successfully before installation
- [ ] Install Lumina-OS launcher is visible on the desktop
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
- none yet

## Blockers
- none yet

## Notes
- record partitioning choices here
- record installer warnings or package failures here
- record post-install first-boot observations here
