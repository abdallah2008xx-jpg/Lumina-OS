# Lumina-OS Reporting Guide

Keep reporting lightweight.

## Files
- `PROJECT-SUMMARY.md` -> fast done-vs-remaining project snapshot
- `CURRENT-STATUS.md` -> very short overall project snapshot
- `SHAREABLE-UPDATE.md` -> generated update suitable for sharing outside the repo
- `SHAREABLE-BRIEF.md` -> short English shareable version
- `SHAREABLE-BRIEF-AR.md` -> short Arabic shareable version
- `HOURLY-STATUS.md` -> latest work-block update
- `PROGRESS-LOG.md` -> chronological milestone log
- `STATUS-YYYY-MM-DD.md` -> day-specific summary if needed
- `HOURLY-STATUS-TEMPLATE.md` -> copy from this for new updates
- `builds/` -> Arch-side build manifests
- `build-handoffs/` -> summaries for complete manifest+ISO handoff folders imported from a separate Arch build environment
- `build-imports/` -> records for build manifests imported from a separate Arch clone or VM
- `iso-imports/` -> records for ISO files imported back into this workspace from a separate Arch clone or VM
- `cycle-handoffs/` -> generated runbooks for full build/VM/release cycles
- `cycle-chain-audits/` -> run-label evidence-link audits across build, VM, session, blockers, and readiness
- `vm-tests/` -> VM test reports grouped by date
- `diagnostics/` -> imported diagnostics bundles from live-session exports
- `release-candidates/` -> current release-candidate summaries and publish readiness
- `shareable-updates/` -> dated generated snapshots for external progress sharing
- `releases/` -> prepared release manifests, draft notes, checksums, release validation reports, and GitHub publish records
- `test-sessions/` -> linked build/test summaries across one run
- `test-session-audits/` -> verification reports for the linked evidence chain
- `blockers/` -> current blocker state plus dated blocker reviews
- `readiness/` -> current build/test readiness plus dated readiness snapshots
- `validation-matrix/` -> side-by-side coverage for `stable` and `login-test`

## Recommended Flow
1. Update `HOURLY-STATUS.md` during active work
2. Append major completed steps to `PROGRESS-LOG.md`
3. Refresh `CURRENT-STATUS.md` when the project state changes
4. Use `STATUS-YYYY-MM-DD.md` for end-of-day recap if useful
5. Keep build manifests and VM test reports once real ISO runs begin
6. If the Arch environment exported one folder containing both the build manifest and ISO, import that handoff folder first
7. Import any build manifest that was produced outside this repo clone before starting the VM cycle
8. Import any ISO file that was produced outside this repo clone before starting release preparation
9. Generate a cycle handoff before a serious run if you want one shared command sheet
10. Import diagnostics bundles and connect them to a session summary after VM runs
11. Audit the completed session summary before treating it as the current reference run
12. Sync blockers so the current run has a central blocker state
13. Sync readiness so the current run has a single high-level go/no-go status
14. Sync the validation matrix so both build modes are tracked side by side
15. Review the cycle-chain audit before treating a run as the clean release candidate
16. Prepare a release candidate so publish readiness has one current summary file
17. Refresh the same release candidate after publish so the current summary reflects the published state
18. Keep the GitHub release context report with the release package so publish intent stays auditable
19. Refresh `SHAREABLE-UPDATE.md` when the public-facing project state changes
20. Refresh the short shareable briefs when you want a copy-paste-ready update for chat or social posting

## What to Record
- What was finished
- What is in progress
- What comes next
- Any blocker
- Any important technical decision

## Good Update Style
- Short bullets
- Clear verbs
- Real progress only
- Mention blockers early
- Avoid long explanations unless a decision matters

## Suggested Rule
If a task took real effort, changed project direction, or affected boot/build behavior, log it.

## Cycle Label Rule
When starting and finishing a VM cycle, prefer the same `Run Label` so VM reports, session summaries, diagnostics imports, audits, blocker reviews, and readiness snapshots all stay linked to the same exact run.

Use the same `Run Label` during the Arch build as well, so the build manifest can be matched to the later VM and release records without depending on whichever build was most recent.

## CI Note
GitHub Actions now runs both structural validation and a workflow smoke test. If CI fails, check whether a workflow script changed behavior even if the repo structure still looks correct.
