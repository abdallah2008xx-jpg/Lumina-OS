# Lumina-OS Login-Test Records

Keep dedicated `login-test` evidence here.

## Intended Contents
- one focused report per labeled `login-test` pass
- SDDM layout and manual-login notes
- links back to the matching VM/session evidence chain

## Recommended Flow
1. Build or import a `login-test` ISO with a clear `Run Label`
2. Start the VM cycle with `scripts/start-vm-test-cycle.ps1 -Mode login-test`
3. Create a focused report with `scripts/new-login-test-report.ps1`
4. Boot the ISO and validate SDDM plus manual login
5. Finish the cycle with `scripts/finish-vm-test-cycle.ps1`
6. Review blockers, readiness, validation matrix, and keep the login-test report linked to that same label
