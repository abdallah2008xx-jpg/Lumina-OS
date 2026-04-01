# Hourly Status - Lumina-OS

Use this file for the latest active progress snapshot.
Update it once per work block or roughly every hour.

## Current Block
- **Date:** 2026-04-01
- **Time:** 12:13 PDT
- **Focus:** Adding a real GitHub Actions ISO build workflow so remote build attempts can start without local Arch access
- **Owner:** Abdallah / assistant

## Done This Hour
- Added `.github/workflows/build-iso.yml` to build `stable` and `login-test` remotely on GitHub Actions
- Wired the workflow to export the same handoff structure used by the local Arch->Windows flow
- Updated docs and status files so the remote-build path is part of the official process

## In Progress
- Re-validating the repo after the GitHub remote-build workflow pass and preparing the next commit

## Next Hour
- Run validation and push the remote-build workflow to GitHub
- Keep the build/test workflow stable and ready for the first Arch-side `stable` build
- Review the first GitHub Actions ISO build and its uploaded handoff artifacts
- Verify the complete handoff path during the first real Arch->Windows transfer if build and release work happen in different environments

## Blockers
- Actual ISO building is blocked in the current Windows workspace; `mkarchiso` must run inside an Arch environment

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

## Ready-to-Send Mini Update
Lumina-OS now has a real GitHub Actions ISO build workflow, so first build attempts can start remotely while still producing the same handoff structure used by the local Arch->Windows process.
