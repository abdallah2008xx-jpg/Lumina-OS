# Lumina-OS Release Evidence Packs

Keep one manifest here when you want to prepare `login-test`, `install`, and `hardware` evidence with one shared `Run Label`.

## Recommended Flow
1. Create an evidence pack with `scripts/new-release-evidence-pack.ps1`
2. Use the generated report paths during the real validation run
3. Pass the same pack into:
   - `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`

## Intended Contents
- one manifest per shared evidence set
- links to login-test, install, and hardware reports
- one exact `Run Label` to carry into release gating
