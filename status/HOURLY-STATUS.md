# Hourly Status - Lumina-OS

Use this file for the latest active progress snapshot.
Update it once per work block or roughly every hour.

## Current Block
- **Date:** 2026-04-01
- **Time:** 14:22 PDT
- **Focus:** Converting the first real `stable` VM findings into source-side fixes before the rerun
- **Owner:** Abdallah / assistant

## Done This Hour
- Fixed the GitHub Actions workflow parser issue around matrix-based mode selection
- Fixed remote script execution by calling Arch-side helpers through `bash`
- Added remote build log capture plus public failure-tail annotations for CI debugging
- Made Arch bootstrap non-interactive and added `grub` so `mkarchiso` host validation can pass remotely
- Fixed a bash-conditional bug in `scripts/validate-profile.sh`
- Reached the first successful real GitHub Actions matrix build for `stable` and `login-test`
- Added a direct GitHub Actions artifact-import path so downloaded workflow zips can go straight into local VM validation
- Added a one-command GitHub Actions artifact -> VM-cycle bridge for faster first-ISO validation
- Added direct GitHub Actions artifact download by `RunId + mode` so the bridge no longer depends on a manual zip download first
- Added a matching GitHub Actions cycle-finish wrapper so diagnostics import can reuse the same run context without retyping labels manually
- Imported the `stable` handoff from GitHub Actions run `#8` and initialized the first local VM cycle on `gha-stable-8-1`
- Booted the imported `stable` ISO in VirtualBox and confirmed the guest reaches a live Plasma X11 session
- Exported and imported real diagnostics from the running `stable` VM, then closed the first real cycle through blockers/readiness/validation
- Captured three concrete blockers from the first real `stable` cycle: black host-side VirtualBox screenshots, early firstboot timing, and smoke-check session detection gaps
- Added a shared session-context helper for guest-side runtime detection
- Updated firstboot to wait for Welcome/session-default artifacts and to refresh after Welcome closes
- Fixed session-default writes so `ColorScheme` is written into the real `~/.config/kdeglobals` path
- Updated smoke checks and diagnostics export to resolve session type/desktop with loginctl/process fallbacks instead of raw environment variables only
- Added a VirtualBox guest-side screenshot fallback helper inside the ISO plus a host-side PowerShell capture helper
- Finished importing the `login-test` handoff from run `#8` and initialized its first local VM evidence chain on `gha-login-test-8-1`

## In Progress
- Updating docs and generated status files so the `stable` blocker fixes and rerun path are reflected clearly at the project level
- Preparing the next actual rerun targets: `stable` after fixes, then `login-test` for SDDM/manual-login validation

## Next Hour
- Rerun the `stable` VM cycle after the new firstboot, smoke-check, and screenshot-fallback fixes
- Boot the imported `login-test` ISO and validate SDDM/manual login
- Verify the new diagnostics-bundle finish wrapper again on a clean rerun if needed

## Blockers
- The first real `stable` cycle is blocked by three runtime issues: black host-side VirtualBox screenshots despite a live desktop, firstboot report timing that misses Welcome artifacts, and smoke-check session detection reporting `unknown`

## Decisions / Notes
- Prefer GitHub as the intended release-metadata source now that the real repo exists
- Keep a bundled metadata fallback until the first public release is actually published
- Keep internal `ahmados-*` paths and IDs stable for now unless we do a deliberate compatibility-preserving second pass
- Do not rely on latest-build matching when a real run label can be carried through the cycle
- Prefer a generated handoff file before the first serious stable cycle so every step is written down once
- Let CI exercise the workflow scripts themselves, not only the repo structure
- Let the selected mode decide the operator checklist instead of reusing one merged path
- Treat release prep as blocked if the recorded run no longer points to one clean evidence chain
- Treat publish readiness as a first-class tracked state, not just a set of loose files under `status/releases/`
- Treat the published state as another tracked transition, not something inferred manually from GitHub only
- Treat publish context as its own gate so the chosen manifest must still match the current candidate
- Treat public progress updates as generated artifacts, not hand-maintained text
- Treat short social-style updates as derived artifacts from the same canonical project state
- Prefer compatibility-preserving aliases for now instead of renaming deep runtime IDs before the first real ISO validation
- Treat external Arch-side build manifests as first-class evidence and import them before the Windows-side VM chain starts
- Treat external Arch-side ISO files as first-class release inputs and import them before release preparation in this workspace
- Prefer one complete build handoff folder when the Arch side can export both files together
- Use GitHub Actions as the first practical build engine when local Arch remains blocked
- Treat the first successful remote build as the handoff point into VM validation, not the end of the process
- Prefer run-id-based artifact download when the successful build already exists on GitHub, so operators do not need to hunt for the right zip manually
- Prefer a matching run-id-based finish wrapper so the same remote build context survives diagnostics import and final evidence sync
- Treat the first real `stable` cycle as a success for boot/access testing, but blocked for promotion until the three runtime issues are fixed
- Prefer a guest-side VirtualBox screenshot fallback over trusting blank host-side `screenshotpng` output during headless validation

## Ready-to-Send Mini Update
Lumina-OS completed its first real `stable` VM validation cycle, confirmed Plasma X11 boots, and has now landed source-side fixes for the three recorded blockers ahead of the next rerun.
