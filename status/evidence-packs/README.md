# Lumina-OS Release Evidence Packs

Keep one manifest here when you want to prepare `login-test`, `install`, and `hardware` evidence with one shared `Run Label`.

## Recommended Flow
1. Create an evidence pack with `scripts/new-release-evidence-pack.ps1`
2. Use the generated report paths during the real validation run
3. Pass the same `Run Label` or explicit report paths into:
   - `scripts/audit-release-evidence.ps1`
   - `scripts/audit-release-readiness.ps1`
   - `scripts/prepare-release-candidate.ps1`

## Intended Contents
- one manifest per shared evidence set
- links to login-test, install, and hardware reports
- one exact `Run Label` to carry into release gating
