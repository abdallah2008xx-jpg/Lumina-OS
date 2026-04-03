# Lumina-OS Install Test Records

Store installer-focused VM validation reports here by date.

## Recommended Flow
1. Create a fresh report with `scripts/new-install-test-report.ps1`
2. Or initialize the same report directly from a GitHub Actions artifact with `scripts/start-github-actions-install-test.ps1`
3. Boot a fresh ISO on a blank VM disk
4. Launch `Install Lumina-OS`
5. Fill installer findings and blockers immediately
6. Record whether the installed system boots successfully after setup

## Naming
- the helper script writes reports under `status/install-tests/YYYY-MM-DD/`
- keep one report per installer attempt
