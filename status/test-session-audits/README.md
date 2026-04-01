# AhmadOS Test Session Audits

Store audit reports here after checking that a session summary still points to real evidence.

## Recommended Flow
1. Finish the VM cycle with `scripts/finish-vm-test-cycle.ps1`
2. Review the generated audit under `status/test-session-audits/`
3. Fix any broken or placeholder evidence references
4. Rerun `scripts/audit-test-session.ps1` if you want a fresh pass after edits

## Typical Checks
- build manifest path exists
- VM report path exists
- diagnostics bundle path exists
- diagnostics import manifest exists
- imported summary, firstboot report, and smoke-check report are present
- session notes are not left in placeholder state
