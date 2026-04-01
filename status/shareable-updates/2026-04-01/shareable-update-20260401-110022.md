# Lumina-OS Shareable Update

- Generated At: 2026-04-01T11:00:22
- Readiness State: needs-build
- Validation Matrix State: needs-first-build
- Release Candidate State: not-recorded-yet
- Current Run Label: not-recorded-yet
- Current Version: not-recorded-yet

## Current State
- Lumina-OS has strong build/test/release workflow coverage and is waiting on the first real Arch-side execution cycle.
- Readiness state: needs-build
- Validation matrix state: needs-first-build
- Release candidate state: not-recorded-yet

## Recent Progress
- compatibility-preserving `lumina-*` runtime aliases now exist for live-session commands while the older `ahmados-*` entrypoints remain available
- build manifests can now be imported back into this repo from a separate Arch clone or VM before starting the Windows-side VM cycle
- ISO artifacts can now be imported back into this workspace from a separate Arch clone or VM so release preparation can use a local Windows-accessible path
- complete build handoff folders can now be imported in one step when the Arch side sends the manifest and ISO together
- GitHub Actions now has a real remote ISO build workflow so first build attempts no longer depend only on local Arch access

## What Is Ready
- The core build/test/release workflow is scaffolded and validated locally.
- Linked evidence now covers build manifests, VM reports, session audits, readiness, validation matrix, and release-candidate state.
- GitHub publish now has local release-context validation before release creation.

## What Is Still Missing
- The first real Arch build and first real VM evidence chain.
- The first real release candidate built from a real ISO.
- The first real published Lumina-OS release on GitHub.

## Immediate Next Step
- run `stable` and `login-test` builds in a real Arch environment
- test the real Welcome choice application inside a built ISO
- test the metadata-backed Update Center inside a built ISO
- inspect the generated firstboot report inside a built ISO
- confirm the firstboot report launcher behaves correctly inside a built ISO
