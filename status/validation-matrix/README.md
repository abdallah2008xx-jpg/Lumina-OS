# AhmadOS Validation Matrix

Store multi-mode coverage snapshots here after syncing the latest `stable` and `login-test` evidence.

## Recommended Flow
1. Finish a VM cycle with `scripts/finish-vm-test-cycle.ps1`
2. Review `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md`
3. Open the dated snapshot under `status/validation-matrix/YYYY-MM-DD/`
4. Use the matrix to see which mode is ready, blocked, or still missing evidence

## Typical Inputs
- latest `stable` build/test/audit/blocker chain
- latest `login-test` build/test/audit/blocker chain
- current project-wide validation coverage
