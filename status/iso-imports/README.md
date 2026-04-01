# Lumina-OS ISO Artifact Imports

Store import records here when a real ISO is copied back from a separate Arch VM or clone into this workspace for release preparation.

## Recommended Flow
1. Build the ISO inside the Arch environment
2. Copy the ISO file back to this workspace
3. Import it with `scripts/import-iso-artifact.ps1`
4. Reuse the same `Run Label` so `prepare-release-candidate.ps1` can resolve the imported local ISO automatically

## Typical Contents
- source ISO path
- imported local ISO path under `build/imported-iso/`
- mode
- run label
- size and SHA256
