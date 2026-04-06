# Lumina-OS Release Evidence Packs

Keep one manifest here when you want to prepare `login-test`, `install`, and `hardware` evidence with one shared `Run Label`.

## Recommended Flow
1. Preferred: start a full session with `scripts/start-release-evidence-session.ps1`
2. Or create an evidence pack directly with `scripts/new-release-evidence-pack.ps1`
3. Use the generated `release-evidence-runbook-*.md`, session note, and report paths during the real validation run
4. Refresh the pack after report updates with `scripts/sync-release-evidence-pack.ps1 -EvidencePackPath "<path-to-pack>"`
5. Pass the same pack into:
   - `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
6. Review `CURRENT-EVIDENCE-PACK.md` when you want the latest synced pack summary in one place
7. Review `../releases/CURRENT-RELEASE-CONTROL-CENTER.md` when you want the top-level release state after evidence, readiness, and candidate syncs

## Intended Contents
- one manifest per shared evidence set
- one generated runbook per shared evidence set
- one generated session note per shared evidence set
- one synced state snapshot per shared evidence set
- a current pointer to the latest synced evidence pack
- links to login-test, install, and hardware reports
- one exact `Run Label` to carry into release gating
