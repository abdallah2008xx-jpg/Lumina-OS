# Contributing To Lumina-OS

## Goal
Keep Lumina-OS moving in a clean, testable, reviewable way.

## Execution Plan
- See `docs/TEAM-EXECUTION-PLAN.md` for the current Lumina-OS execution order and ownership notes.

## Working Model
- Use GitHub Issues to define the task before starting larger work.
- Create a branch for each change.
- Prefer branch names like `feature/...`, `fix/...`, `docs/...`, or `build/...`.
- Do not push unreviewed work directly to `main`.
- Open a Pull Request for every meaningful change.

## Before You Open A PR
- Run `powershell -ExecutionPolicy Bypass -File .\scripts\validate-profile.ps1`
- If you changed build or VM workflow docs, keep the status files aligned.
- If you changed user-facing text, keep the Lumina-OS name consistent.
- If you touched compatibility-sensitive runtime IDs such as `ahmados-*` or `com.ahmados.*`, call that out clearly in the PR.

## Build And Test Notes
- Real ISO builds must run inside a real Arch environment.
- The current Windows workspace is for editing, validation, status tracking, and GitHub workflow prep.
- When a real build happens, keep the evidence chain complete:
  - build manifest
  - VM report
  - diagnostics import
  - session summary
  - session audit
  - blocker sync
  - readiness snapshot
  - validation matrix

## Pull Request Expectations
- Keep the title short and specific.
- Describe what changed.
- Describe why it changed.
- List validation that was actually run.
- Mention any blocker, risk, or follow-up work.

## Status Logging
Update these when the change is meaningful:
- `status/CURRENT-STATUS.md`
- `status/PROGRESS-LOG.md`
- `status/HOURLY-STATUS.md`

## Current Rename Policy
- Visible branding should use `Lumina-OS`.
- Internal compatibility identifiers may still use `ahmados-*` until the first real ISO validation is complete.
- Do not rename internal IDs casually across the repo without checking the build/test impact.
