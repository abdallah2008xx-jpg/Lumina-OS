# Lumina-OS Install Test Records

Store installer-focused VM validation reports here by date.

## Recommended Flow
1. Create a fresh report with `scripts/new-install-test-report.ps1`
2. Boot a fresh ISO on a blank VM disk
3. Launch `Install Lumina-OS`
4. Fill installer findings and blockers immediately
5. Record whether the installed system boots successfully after setup

## Naming
- the helper script writes reports under `status/install-tests/YYYY-MM-DD/`
- keep one report per installer attempt
