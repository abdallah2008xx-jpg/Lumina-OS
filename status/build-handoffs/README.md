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
2. Download the artifact zip for the mode you want to test
3. Import that zip with `scripts/import-github-actions-artifact.ps1`
4. Reuse the imported run label during VM testing and release preparation

## Typical Contents
- handoff folder path
- imported build manifest path
- imported ISO path
- reported mode
- reported run label
- GitHub Actions artifact zip path when the source was a remote run
