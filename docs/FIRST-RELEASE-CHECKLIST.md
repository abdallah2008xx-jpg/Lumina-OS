# First Release Checklist

## Goal
Ship the first public Lumina-OS test ISO with evidence, not guesswork.

## Pre-Build
- [ ] `scripts/validate-profile.ps1` passes locally
- [ ] `scripts/validate-profile.sh` passes in Arch
- [ ] `archiso-profile/airootfs/etc/ahmados-release.conf` points to the correct GitHub owner and repo
- [ ] `CHANGELOG.md` is updated for the release
- [ ] `status/CURRENT-STATUS.md` reflects the current state

## Stable Build
- [ ] Run `./scripts/build-iso-arch.sh --mode stable`
- [ ] Confirm the ISO exists
- [ ] Confirm a build manifest is written under `status/builds/`

## Stable VM Cycle
- [ ] Start a labeled cycle with `.\scripts\start-vm-test-cycle.ps1`
- [ ] Boot the ISO in a VM
- [ ] Confirm Plasma session entry
- [ ] Confirm Welcome behavior
- [ ] Confirm Update Center behavior
- [ ] Confirm firstboot report generation
- [ ] Run smoke checks
- [ ] Export diagnostics
- [ ] Finish the cycle with `.\scripts\finish-vm-test-cycle.ps1`
- [ ] Review blockers, readiness, and validation matrix

## Login-Test Build
- [ ] Run `./scripts/build-iso-arch.sh --mode login-test`
- [ ] Confirm the ISO exists
- [ ] Confirm a build manifest is written under `status/builds/`

## Login-Test VM Cycle
- [ ] Start a labeled cycle with `.\scripts\start-vm-test-cycle.ps1`
- [ ] Boot the ISO in a VM
- [ ] Confirm SDDM appears correctly
- [ ] Confirm manual login reaches Plasma
- [ ] Confirm theming and runtime behavior
- [ ] Export diagnostics
- [ ] Finish the cycle with `.\scripts\finish-vm-test-cycle.ps1`
- [ ] Review blockers, readiness, and validation matrix

## Release Gate
- [ ] `status/readiness/CURRENT-READINESS.md` is no longer `needs-build`
- [ ] `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md` shows acceptable mode coverage
- [ ] No blocking issue remains for the chosen release candidate
- [ ] ISO checksum is generated
- [ ] Release notes are written
- [ ] `.\scripts\prepare-release-package.ps1 -Version "<version>" -IsoPath "<path-to-iso>" -Mode stable -RunLabel "<run-label>"` has been run

## GitHub Release Package
- [ ] ISO asset
- [ ] SHA256 checksum
- [ ] Short release summary
- [ ] Known issues
- [ ] Build mode tested
- [ ] VM platform tested
- [ ] Link to relevant build/test evidence inside the repo
- [ ] Generated release package is stored under `status/releases/`
