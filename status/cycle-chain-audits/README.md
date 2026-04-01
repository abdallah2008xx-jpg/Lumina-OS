# Lumina-OS Cycle Chain Audits

Store per-run chain audits here.

## Intended Contents
- one report per `Run Label`
- verification that build, VM, session, audit, blocker, and readiness files all point at the same run
- warnings when current summary files or validation coverage drift away from the audited run

## Recommended Flow
1. Finish a labeled VM cycle with `scripts/finish-vm-test-cycle.ps1`
2. Confirm a cycle-chain audit is written here
3. Review warnings before treating the run as the clean release candidate
4. Include the cycle-chain audit in the prepared release package evidence
