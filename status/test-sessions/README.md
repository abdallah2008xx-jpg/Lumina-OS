# Lumina-OS Test Sessions

Store one high-level summary per real build-and-test cycle here.

## Intended Purpose
- link the build manifest
- link the VM report
- link the diagnostics bundle path
- summarize blockers and next decisions

## Recommended Flow
1. Build the ISO in Arch
2. Let `status/builds/` capture the build manifest
3. Start the test cycle with `scripts/start-vm-test-cycle.ps1`
4. Boot the ISO and fill the VM report under `status/vm-tests/`
5. Finish the cycle with `scripts/finish-vm-test-cycle.ps1` after exporting diagnostics
6. Review the generated audit under `status/test-session-audits/`
7. Review `status/blockers/CURRENT-BLOCKERS.md`
8. Review `status/readiness/CURRENT-READINESS.md`
9. Add final findings and decisions to the updated session summary
