# Lumina-OS Validation Matrix

- Evaluated At: 2026-04-01T14:14:17
- Overall State: blocked

## Mode Summary
- stable: blocked
- login-test: needs-build

## Global Summary
- Ready modes: 0 / 2
- Blocked modes: 1
- Attention modes: 0

## stable
- Mode State: blocked
- Build State: build-recorded
- Build Manifest: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\builds\2026-04-01\build-imported-20260401-141411-stable-gha-stable-8-1.md
- Session Summary: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\test-sessions\2026-04-01\test-session-gha-stable-8-1.md
- Session Audit: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\test-session-audits\2026-04-01\test-session-audit-gha-stable-8-1.md
- Blocker Review: C:\Users\abdal\Downloads\AhmadOS-Rebuild\status\blockers\2026-04-01\blocker-review-gha-stable-8-1.md
- ISO File: lumina-os-0.1.0-dev-x86_64.iso
- ISO Full Path: /repo/build/github-out/stable/lumina-os-0.1.0-dev-x86_64.iso

### Open Blockers
- [vm] Investigate why VirtualBox headless screenshots remain black while the guest desktop is visible from an internal X11 capture.
- [vm] Revisit firstboot timing so Welcome artifacts are present before `firstboot-report.md` is written.
- [vm] Revisit smoke-check environment detection so active Plasma session values are not reported as `unknown`.

### Attention Items
- Session decision summary still contains the default placeholder text.
- Session notes still contain the default placeholder guidance.

### Next Step
- fix the open stable blockers before continuing

## login-test
- Mode State: needs-build
- Build State: missing-build
- Build Manifest: not-recorded-yet
- Session Summary: not-recorded-yet
- Session Audit: not-recorded-yet
- Blocker Review: not-recorded-yet
- ISO File: not-recorded-yet
- ISO Full Path: not-recorded-yet

### Open Blockers
- none

### Attention Items
- none

### Next Step
- run the first login-test Arch build

## Recommendation
- at least one mode is blocked; fix that mode before treating the matrix as healthy
