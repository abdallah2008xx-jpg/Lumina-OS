# Lumina-OS Build Handoffs

Store import summaries here when a complete Arch-side build handoff folder is brought back into this workspace.

## Recommended Flow
1. Build the ISO inside the Arch environment
2. Export a handoff folder there with `scripts/export-build-handoff.sh`
3. Copy that folder into the Windows workspace
4. Import it with `scripts/import-build-handoff.ps1`
5. Reuse the same `Run Label` during VM testing and release preparation

## Typical Contents
- handoff folder path
- imported build manifest path
- imported ISO path
- reported mode
- reported run label
