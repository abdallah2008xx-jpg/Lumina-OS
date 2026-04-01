# Lumina-OS VM Test Records

Store VM test reports here by date.

## Recommended Flow
1. Create a fresh report with `scripts/new-vm-test-report.ps1`
2. Boot the ISO in the target VM
3. Fill the checklist and blockers immediately
4. Reference the matching build manifest when possible

## Naming
- the helper script writes reports under `status/vm-tests/YYYY-MM-DD/`
- keep one report per VM run
