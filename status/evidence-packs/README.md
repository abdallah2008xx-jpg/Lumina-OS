# Lumina-OS Release Evidence Packs

Keep one manifest here when you want to prepare `login-test`, `install`, and `hardware` evidence with one shared `Run Label`.

## Recommended Flow
1. Preferred: start a full session with `scripts/start-release-evidence-session.ps1`
2. Or create an evidence pack directly with `scripts/new-release-evidence-pack.ps1`
3. Use the generated `release-evidence-runbook-*.md`, session note, and report paths during the real validation run
4. Preferred after report updates: refresh the whole session with `scripts/sync-release-evidence-session.ps1 -EvidenceSessionPath "<path-to-session>"`
5. Or refresh the pack only with `scripts/sync-release-evidence-pack.ps1 -EvidencePackPath "<path-to-pack>"`
6. If you want to jump straight to the next missing evidence file, run `scripts/open-next-release-evidence.ps1`
   - pass `-Open` to open the resolved file immediately
7. Pass the same pack into:
   - `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"`
   - `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
8. Review `CURRENT-EVIDENCE-SESSION.md` when you want the latest practical evidence-session summary in one place
   - it now shows the next missing evidence target, its direct report path, its tester, and its checklist progress
9. Review `CURRENT-EVIDENCE-PACK.md` when you want the latest synced pack summary in one place
   - it now shows `Evidence Ready Count` and `Evidence Checklist Progress` across login-test, install, and hardware
10. Review `../releases/CURRENT-RELEASE-CONTROL-CENTER.md` when you want the top-level release state after evidence, readiness, and candidate syncs

## Intended Contents
- one manifest per shared evidence set
- one generated runbook per shared evidence set
- one generated session note per shared evidence set
- one session sync path to keep the note aligned with live report states
- one current pointer to the latest evidence session
- one synced state snapshot per shared evidence set
- a current pointer to the latest synced evidence pack
- pack/session summaries that surface real checklist progress instead of only high-level status
- links to login-test, install, and hardware reports
- one exact `Run Label` to carry into release gating
