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
- [ ] Confirm the Install Lumina-OS launcher opens `archinstall`
- [ ] Confirm Update Center behavior
- [ ] Confirm firstboot report generation
- [ ] Run smoke checks
- [ ] Export diagnostics
- [ ] Finish the cycle with `.\scripts\finish-vm-test-cycle.ps1`
- [ ] Review blockers, readiness, validation matrix, and cycle-chain audit

## Install Path
- [ ] Create an installer validation report with `.\scripts\new-install-test-report.ps1`
- [ ] Follow `docs/INSTALLER-VM-TEST-CHECKLIST.md`
- [ ] Boot the ISO on a blank VM disk
- [ ] Launch `Install Lumina-OS`
- [ ] Complete one end-to-end install path without installer errors
- [ ] Reboot into the installed system
- [ ] Confirm the installed system reaches Plasma successfully

## Login-Test Build
- [ ] Run `./scripts/build-iso-arch.sh --mode login-test`
- [ ] Confirm the ISO exists
- [ ] Confirm a build manifest is written under `status/builds/`

## Login-Test VM Cycle
- [ ] Create a dedicated login-test report with `.\scripts\new-login-test-report.ps1`
- [ ] Follow `docs/LOGIN-TEST-VM-CHECKLIST.md`
- [ ] Start a labeled cycle with `.\scripts\start-vm-test-cycle.ps1`
- [ ] Boot the ISO in a VM
- [ ] Confirm SDDM appears correctly
- [ ] Confirm manual login reaches Plasma
- [ ] Confirm theming and runtime behavior
- [ ] Export diagnostics
- [ ] Finish the cycle with `.\scripts\finish-vm-test-cycle.ps1`
- [ ] Review blockers, readiness, validation matrix, and cycle-chain audit

## Real Hardware Validation
- [ ] Create a hardware validation report with `.\scripts\new-hardware-test-report.ps1`
- [ ] Follow `docs/HARDWARE-TEST-CHECKLIST.md`
- [ ] Boot the ISO or installed system on at least one real device
- [ ] Run `Lumina-OS Hardware Readiness Check`
- [ ] Confirm Wi-Fi, audio, graphics, and storage basics
- [ ] Record blockers immediately if any core hardware path fails

## Release Gate
- [ ] Optional but recommended: create one shared evidence pack with `.\scripts\new-release-evidence-pack.ps1 -Mode stable -RunLabel "<run-label>"`
- [ ] `status/readiness/CURRENT-READINESS.md` is no longer `needs-build`
- [ ] `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md` shows acceptable mode coverage
- [ ] No blocking issue remains for the chosen release candidate
- [ ] The selected run has a passing or acceptable cycle-chain audit
- [ ] A completed install test report exists for the selected candidate
- [ ] A completed real-device hardware test report exists for the selected candidate
- [ ] If auto-selected evidence falls back to an older or different `Run Label`, review the release candidate summary before publish
- [ ] For strict release gating, run `prepare-release-candidate.ps1` and `validate-github-release-context.ps1` with `-RequireExactEvidenceRunLabel`
- [ ] Run `.\scripts\audit-release-evidence.ps1 -Version "<version>" -Mode stable -RunLabel "<run-label>"` before the final RC pass to inspect soft vs strict evidence readiness
- [ ] Run `.\scripts\audit-release-readiness.ps1 -Version "<version>" -Mode stable -RunLabel "<run-label>"` after RC prep to confirm the final go/no-go state
- [ ] If the ISO was built in a separate Arch clone or VM, a local Windows-accessible copy has been imported with `.\scripts\import-iso-artifact.ps1`
- [ ] If the build manifest and ISO were transferred together, the handoff folder has been imported with `.\scripts\import-build-handoff.ps1`
- [ ] ISO checksum is generated
- [ ] Release notes are written
- [ ] `.\scripts\prepare-release-candidate.ps1 -Version "<version>" -IsoPath "<path-to-iso>" -Mode stable -RunLabel "<run-label>"` has been run with matching install and hardware evidence available or passed explicitly via `-InstallReportPath` and `-HardwareReportPath`
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
