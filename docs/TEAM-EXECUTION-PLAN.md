# Lumina-OS Execution Plan

## Purpose
This plan now reflects the current project reality:
- Mohammad is no longer active on the project
- Abdullah owns the full execution path
- the former UI/UX track has been absorbed into the main implementation track

The goal is to keep work ordered, avoid duplicated effort, and protect the build/test path while Lumina-OS moves toward its first real ISO.

## Working Rules
- keep `main` stable and readable
- prefer one focused branch per task when work is done from multiple machines
- do not mix build/test workflow changes with deep compatibility renames unless there is a clear reason
- update status files when a meaningful stage is completed
- treat internal compatibility identifiers such as `ahmados-*` and `com.ahmados.*` as stable until after the first real ISO validation

## Current Ownership
Abdullah now owns both tracks:
- build, boot, validation, evidence, and release preparation
- Welcome, Update Center, SDDM, visual polish, and UI copy

## Build And Validation Ownership
Primary ownership remains with these paths:
- `archiso-profile/profiledef.sh`
- `archiso-profile/packages.x86_64`
- `archiso-profile/build-variants/`
- `archiso-profile/grub/`
- `archiso-profile/syslinux/`
- `archiso-profile/efiboot/`
- `scripts/build-iso-arch.sh`
- `scripts/build-iso.ps1`
- `scripts/bootstrap-arch-build-env.sh`
- `scripts/validate-profile.ps1`
- `scripts/validate-profile.sh`
- `scripts/write-build-manifest.sh`
- `scripts/start-vm-test-cycle.ps1`
- `scripts/finish-vm-test-cycle.ps1`
- `scripts/new-vm-test-report.ps1`
- `scripts/new-test-session.ps1`
- `scripts/audit-test-session.ps1`
- `scripts/sync-test-blockers.ps1`
- `scripts/sync-readiness-status.ps1`
- `scripts/sync-validation-matrix.ps1`
- `scripts/import-diagnostics-bundle.ps1`
- `scripts/prepare-release-package.ps1`
- `status/builds/`
- `status/vm-tests/`
- `status/test-sessions/`
- `status/test-session-audits/`
- `status/diagnostics/`
- `status/blockers/`
- `status/readiness/`
- `status/validation-matrix/`
- `status/releases/`

## Former Mohammad Track Now Absorbed
These paths are now part of the same main execution stream:
- `archiso-profile/airootfs/usr/share/ahmados/welcome/`
- `archiso-profile/airootfs/usr/share/ahmados/update-center/`
- `archiso-profile/airootfs/usr/share/sddm/themes/ahmados/`
- `archiso-profile/airootfs/usr/share/color-schemes/`
- `archiso-profile/airootfs/usr/share/ahmados/wallpapers/`
- `branding/`
- `docs/DESKTOP-LAYOUT-SPEC.md`
- `docs/SDDM-THEME-SPEC.md`
- `docs/WELCOME-APP-SPEC.md`
- `docs/WELCOME-IMPLEMENTATION.md`
- `docs/UPDATE-CENTER-SPEC.md`
- `docs/UPDATE-CENTER-IMPLEMENTATION.md`
- `docs/SETTINGS-SHELL-SPEC.md`
- `docs/SYSTEM-THEME-IMPLEMENTATION.md`
- `docs/UX-AGENT-REPORT.md`

## Current Execution Order
1. Finish UI polish that used to belong to the Mohammad track:
   - Welcome clarity and user-facing labels
   - Update Center loading, empty, and error states
   - SDDM wording and test-oriented guidance
   - visual consistency for wallpapers, color names, and channel wording
2. Run the first real `stable` build inside Arch
3. Run the first full labeled VM cycle for `stable`
4. Run the first real `login-test` build inside Arch
5. Run the first full labeled VM cycle for `login-test`
6. Review blockers, readiness, and validation matrix from real evidence
7. Prepare the first release package and publish the first GitHub Release

## Done Criteria For The Absorbed UI Track
This part is considered complete when:
- Welcome shows clearer non-technical labels for saved choices
- Update Center handles `loading`, `empty`, and `error` states clearly
- SDDM copy is aligned with real validation use
- visible product wording stays consistent with `Lumina-OS`
- no UI polish work breaks the existing build/test workflow

## Done Criteria For The Build Track
This part is considered complete when:
- a real build manifest exists
- a real VM report exists
- a real diagnostics import exists
- readiness and validation matrix are driven by actual ISO evidence
- the first release package can be generated from a real build

## Files That Still Need Extra Care
These files can be edited, but changes should stay intentional and well-scoped:
- `README.md`
- `CHANGELOG.md`
- `status/CURRENT-STATUS.md`
- `status/PROJECT-SUMMARY.md`
- `.github/`
- `archiso-profile/airootfs/etc/ahmados-release.conf`

## Practical Note
If a new collaborator joins later, this plan can be split again. For now, Lumina-OS should be treated as a single-owner execution flow so progress stays clean and predictable.
