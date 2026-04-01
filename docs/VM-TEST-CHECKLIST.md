# Lumina-OS VM Test Checklist

## Goal
Keep VM testing consistent across each ISO build.

## Report Creation
Before starting a VM run, you can initialize both the VM report and session summary together with:

```powershell
.\scripts\start-vm-test-cycle.ps1 -Mode stable -VmType VirtualBox -Firmware UEFI
```

For repeated runs of the same mode, prefer a label:

```powershell
.\scripts\start-vm-test-cycle.ps1 -Mode stable -VmType VirtualBox -Firmware UEFI -RunLabel stable-vbox-pass-01
```

If the build was created with `scripts/build-iso.ps1` or `build-iso-arch.sh --run-label`, reuse that exact same label here so the build manifest can be matched directly instead of falling back to the latest build of the same mode.

If you only want the VM report by itself, use:

```powershell
.\scripts\new-vm-test-report.ps1 -Mode stable -VmType VirtualBox -Firmware UEFI
```

After the run, create or update a higher-level session summary separately with:

```powershell
.\scripts\new-test-session.ps1 -Mode stable -VmType VirtualBox -Firmware UEFI
```

If diagnostics were exported from the live session, import them into the repo with:

```powershell
.\scripts\import-diagnostics-bundle.ps1 -BundlePath "C:\Path\To\ahmados-diagnostics-....tar.gz"
```

Or finish the whole cycle in one step after export:

```powershell
.\scripts\finish-vm-test-cycle.ps1 -BundlePath "C:\Path\To\ahmados-diagnostics-....tar.gz" -Mode stable -VmType VirtualBox -Firmware UEFI
```

If the run was started with a label, pass the same label again during finish:

```powershell
.\scripts\finish-vm-test-cycle.ps1 -BundlePath "C:\Path\To\ahmados-diagnostics-....tar.gz" -Mode stable -VmType VirtualBox -Firmware UEFI -RunLabel stable-vbox-pass-01
```

The finish step now also updates:
- `status/test-session-audits/`
- `status/blockers/CURRENT-BLOCKERS.md`
- `status/blockers/YYYY-MM-DD/`
- `status/readiness/CURRENT-READINESS.md`
- `status/readiness/YYYY-MM-DD/`
- `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md`
- `status/validation-matrix/YYYY-MM-DD/`

If you want to rerun the audit for the latest session summary by itself, use:

```powershell
.\scripts\audit-test-session.ps1 -FailOnMissing
```

If you want to refresh the blocker view after editing the reports manually, use:

```powershell
.\scripts\sync-test-blockers.ps1
```

If you want to refresh the high-level readiness status after manual edits, use:

```powershell
.\scripts\sync-readiness-status.ps1
```

If you want to refresh the side-by-side mode coverage after manual edits, use:

```powershell
.\scripts\sync-validation-matrix.ps1
```

## Before Boot
- confirm which build mode was used: `stable` or `login-test`
- record the ISO filename
- record VM type: VirtualBox, VMware, or other
- record VM firmware mode: BIOS or UEFI

## Boot Path
- boot menu appears
- selected boot entry starts correctly
- kernel handoff completes
- live environment does not freeze or black-screen

## Stable Mode Checks
- autologin reaches Plasma
- wallpaper is Lumina-OS branded
- panel layout matches Lumina-OS defaults
- color scheme looks applied

## Login-Test Checks
- SDDM theme appears
- username field is usable
- session selector works
- manual login reaches Plasma

## Plasma Session Checks
- launcher opens
- task manager works
- clock and tray appear correctly
- keyboard and mouse input are responsive
- terminal opens
- file manager opens

## Connectivity Checks
- NetworkManager is active
- wired or wireless networking can be configured
- DNS and browser access work if internet is available

## Guest Environment Checks
- VirtualBox guest behavior is acceptable
- VMware guest behavior is acceptable if tested
- display resize behavior is recorded

## Theme Checks
- SDDM colors and spacing are acceptable
- wallpaper renders correctly
- no obvious unreadable text areas
- Arabic and English text rendering should be noted if tested

## Lumina-OS Runtime Checks
- Welcome opens once for the `live` user
- changing layout, wallpaper, or appearance in Welcome applies after the app closes
- firstboot report is generated at `~/.local/state/ahmados/firstboot-report.md`
- smoke-check report is generated at `~/.local/state/ahmados/smoke-check-report.md`
- Desktop copy of the firstboot report exists if the Desktop directory is present
- `Lumina-OS First Boot Report` launcher opens the generated report or its directory
- `Run Lumina-OS Smoke Checks` creates and opens the smoke-check report
- `Export Lumina-OS Diagnostics` creates a bundle under `~/Documents/Lumina-OS Diagnostics/`
- Update Center opens with release metadata loaded from local cache

## Blocker Format
Record blockers as:
- area
- symptom
- reproduction path
- suspected file or subsystem
