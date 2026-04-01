# Lumina-OS Build Handoffs

Store import summaries here when a complete Arch-side build handoff folder is brought back into this workspace.

## Recommended Flow
1. Build the ISO inside the Arch environment
2. Export a handoff folder there with `scripts/export-build-handoff.sh`
3. Copy that folder into the Windows workspace
4. Import it with `scripts/import-build-handoff.ps1`
5. Reuse the same `Run Label` during VM testing and release preparation

## GitHub Actions Flow
1. Open the successful GitHub Actions run
2. Either download the artifact zip for the mode you want to test, or download it directly with `scripts/download-github-actions-artifact.ps1`
3. Import that zip with `scripts/import-github-actions-artifact.ps1`, or let `scripts/start-github-actions-vm-cycle.ps1` perform download + import + VM-cycle initialization in one path
4. Reuse the imported run label during VM testing and release preparation

## Typical Contents
- handoff folder path
- imported build manifest path
- imported ISO path
- reported mode
- reported run label
- GitHub Actions artifact zip path when the source was a remote run
- direct-download summary when the zip was fetched from GitHub by `RunId`
