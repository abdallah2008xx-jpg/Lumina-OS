# Lumina-OS Arch Build Guide

## Purpose
Provide one reproducible path for building Lumina-OS in a real Arch environment.

## Build Requirement
Run the ISO build inside Arch Linux with:
- `archiso`
- `rsync` or standard coreutils copy support
- enough disk space for the work directory

## Recommended Environments
- Arch Linux bare metal
- Arch Linux virtual machine
- Arch Linux container or chroot only if `mkarchiso` is known to work correctly there

## Pre-Build Validation
Before moving into the Arch build environment, validate the repo locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-profile.ps1
```

The Windows helper below now runs the same validation automatically before printing the Arch build command:

```powershell
.\scripts\build-iso.ps1 -Mode stable
```

It now also prints a suggested `Run Label`. Reuse that same label during the VM cycle so the build manifest, VM report, session summary, readiness snapshot, and release package stay linked.

If you are already inside an Arch VM, bootstrap the build environment with:

```bash
./scripts/bootstrap-arch-build-env.sh --install
```

Inside Arch, the build helper now runs `scripts/validate-profile.sh` automatically before staging the profile and calling `mkarchiso`.
After a successful build, it also writes a build manifest under `status/builds/`.

## Build Modes
### `stable`
- default live-demo mode
- keeps autologin enabled
- best for desktop-first smoke testing

### `login-test`
- disables autologin in the staged build
- exposes the real SDDM login flow
- best for theme and session-entry testing

## Primary Command
From the repo root inside Arch:

```bash
./scripts/build-iso-arch.sh --mode stable
```

To test the real login screen:

```bash
./scripts/build-iso-arch.sh --mode login-test
```

## Optional Paths
```bash
./scripts/build-iso-arch.sh \
  --mode login-test \
  --work /var/tmp/ahmados-work \
  --out /var/tmp/ahmados-out
```

## What the Script Does
1. Copies `archiso-profile/` into a temporary staged profile
2. Applies the requested SDDM login mode only in the staged copy
3. Runs the Arch-side profile validator
4. Runs `mkarchiso`
5. Writes a build manifest that now includes the `Run Label`
6. Leaves the source profile unchanged

## After Build
- use the ISO in a VM first
- review the generated build manifest under `status/builds/`
- create or refresh a session summary under `status/test-sessions/`
- review `status/readiness/CURRENT-READINESS.md` after the VM cycle is finished
- review `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md` to compare `stable` and `login-test`
- record whether the result reaches:
  - boot menu
  - kernel handoff
  - SDDM or autologin desktop
  - working network
  - usable Plasma session
  - generated firstboot report under `~/.local/state/ahmados/firstboot-report.md`

## Recommended Workflow
1. Build `stable`
2. Confirm desktop boot
3. Build `login-test`
4. Confirm SDDM theme and manual login path
5. Create a session summary with `scripts/new-test-session.ps1`
6. Fix blockers before adding deeper UI logic
7. Treat `status/readiness/CURRENT-READINESS.md` as the high-level state of the latest cycle
8. Treat `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md` as the side-by-side state of both build modes
