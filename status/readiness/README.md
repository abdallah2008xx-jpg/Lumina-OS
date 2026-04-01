# Lumina-OS Readiness Records

Store readiness snapshots here after syncing the latest build, test, audit, and blocker state.

## Recommended Flow
1. Finish the VM cycle with `scripts/finish-vm-test-cycle.ps1`
2. Prefer a shared `-RunLabel` when you start and finish the cycle
3. Review `status/readiness/CURRENT-READINESS.md`
4. Open the dated snapshot under `status/readiness/YYYY-MM-DD/`
5. Use the readiness state to decide whether the next step is build, validation, cleanup, or implementation

## Typical Inputs
- latest build manifest
- latest session summary
- latest session audit
- current blocker register
