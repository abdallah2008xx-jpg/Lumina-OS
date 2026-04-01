# Hourly Status - Lumina-OS

Use this file for the latest active progress snapshot.
Update it once per work block or roughly every hour.

## Current Block
- **Date:** 2026-04-01
- **Time:** 09:48 PDT
- **Focus:** Adding release-candidate summaries so prepare/validate output has one current publish-readiness state
- **Owner:** Abdallah / assistant

## Done This Hour
- Added a new release-candidate preparation script above the existing prepare/validate flow
- Added `status/release-candidates/` with a current summary file for publish readiness
- Updated the generated cycle handoff to use release-candidate prep instead of separate manual prepare/validate steps
- Extended the workflow smoke test to cover release-candidate preparation

## In Progress
- Re-validating the repo after the release-candidate pass and preparing the next commit

## Next Hour
- Run validation and push the release-candidate pass to GitHub
- Keep the build/test workflow stable and ready for the first Arch-side `stable` build
- Move execution to an actual Arch environment for the first real ISO build
- Use the new release-candidate summary during the first real labeled VM cycle before publish

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

## Ready-to-Send Mini Update
Lumina-OS now writes one current release-candidate summary on top of the prepared manifest and validation report, so publish readiness is visible without manually opening several files.
