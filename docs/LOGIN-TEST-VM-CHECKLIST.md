# Lumina-OS Login-Test VM Checklist

## Goal
Treat `login-test` as its own evidence chain, not just a note inside the general VM pass.

## Report Creation
Create a dedicated report before or during the run:

```powershell
.\scripts\new-login-test-report.ps1 -VmType VirtualBox -Firmware UEFI -RunLabel login-test-vbox-pass-01
```

Or start the broader labeled VM cycle first, then keep the same label in the login-test report:

```powershell
.\scripts\start-vm-test-cycle.ps1 -Mode login-test -VmType VirtualBox -Firmware UEFI -RunLabel login-test-vbox-pass-01
.\scripts\new-login-test-report.ps1 -VmType VirtualBox -Firmware UEFI -RunLabel login-test-vbox-pass-01
```

## Before Boot
- confirm the ISO was built in `login-test` mode
- confirm the exact `Run Label`
- record VM type and firmware

## SDDM Checks
- SDDM appears instead of autologin
- the Lumina theme renders cleanly
- text is not clipped or overlapping
- clock, header, and helper copy fit inside the available space
- no unusable controls appear off-screen

## Manual Login Checks
- username input is usable
- password input is usable
- session selector works
- login button works
- wrong-password feedback is readable and correctly styled
- manual login reaches Plasma

## Post-Login Checks
- Plasma loads without a black screen
- wallpaper, panel, and session defaults still apply
- Welcome opens if expected
- Update Center opens
- diagnostics export still works

## Evidence
- save screenshots only if they show a layout or usability issue
- keep the matching VM report, session summary, and session audit linked to the same `Run Label`
- update the dedicated login-test report before closing the cycle

## Finish
- run `.\scripts\finish-vm-test-cycle.ps1` with the same `Run Label`
- review blockers, readiness, and validation matrix
- keep the dedicated login-test report under `status/login-tests/`
