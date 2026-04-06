# Lumina-OS Hardware Test Records

Store real-device hardware validation reports here by date.

## Recommended Flow
1. Create a fresh report with `scripts/new-hardware-test-report.ps1`
2. Boot the ISO or installed system on a real device
3. Run `Lumina-OS Hardware Readiness Check`
4. Fill findings and blockers immediately
5. Link the runtime report path inside the hardware notes

## Naming
- the helper script writes reports under `status/hardware-tests/YYYY-MM-DD/`
- keep one report per real-device run
