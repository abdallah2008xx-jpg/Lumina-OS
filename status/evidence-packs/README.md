# Lumina-OS Release Evidence Packs

Keep one manifest here when you want to prepare `login-test`, `install`, and `hardware` evidence with one shared `Run Label`.

## Recommended Flow
1. Create an evidence pack with `scripts/new-release-evidence-pack.ps1`
2. Use the generated `release-evidence-runbook-*.md` and report paths during the real validation run
3. Refresh the pack after report updates with `scripts/sync-release-evidence-pack.ps1 -EvidencePackPath "<path-to-pack>"`
4. Pass the same pack into:
   - `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
5. Review `CURRENT-EVIDENCE-PACK.md` when you want the latest synced pack summary in one place

## Intended Contents
- one manifest per shared evidence set
- one generated runbook per shared evidence set
- one synced state snapshot per shared evidence set
- a current pointer to the latest synced evidence pack
- links to login-test, install, and hardware reports
- one exact `Run Label` to carry into release gating
