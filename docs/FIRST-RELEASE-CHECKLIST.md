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
- [ ] Review blockers, readiness, validation matrix, and cycle-chain audit

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
- [ ] Review blockers, readiness, validation matrix, and cycle-chain audit

## Release Gate
- [ ] `status/readiness/CURRENT-READINESS.md` is no longer `needs-build`
- [ ] `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md` shows acceptable mode coverage
- [ ] No blocking issue remains for the chosen release candidate
- [ ] The selected run has a passing or acceptable cycle-chain audit
- [ ] If the ISO was built in a separate Arch clone or VM, a local Windows-accessible copy has been imported with `.\scripts\import-iso-artifact.ps1`
- [ ] If the build manifest and ISO were transferred together, the handoff folder has been imported with `.\scripts\import-build-handoff.ps1`
- [ ] ISO checksum is generated
- [ ] Release notes are written
- [ ] `.\scripts\prepare-release-candidate.ps1 -Version "<version>" -IsoPath "<path-to-iso>" -Mode stable -RunLabel "<run-label>"` has been run
- [ ] `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` shows a publishable candidate state
- [ ] `.\scripts\validate-github-release-context.ps1 -ReleaseManifestPath "<path-to-release-manifest>"` passes
- [ ] A GitHub token is available through `LUMINA_GITHUB_TOKEN` or `GITHUB_TOKEN`

## GitHub Release Package
- [ ] ISO asset
- [ ] SHA256 checksum
- [ ] Short release summary
- [ ] Known issues
- [ ] Build mode tested
- [ ] VM platform tested
- [ ] Link to relevant build/test evidence inside the repo
- [ ] Generated release package is stored under `status/releases/`
- [ ] `.\scripts\publish-github-release.ps1 -ReleaseManifestPath "<path-to-release-manifest>"` has been run
- [ ] `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows `published`
