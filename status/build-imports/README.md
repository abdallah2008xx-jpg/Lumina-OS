# Lumina-OS Build Manifest Imports

Store import records here when a real Arch build happens in a separate clone or VM and its build manifest must be brought back into the main repo.

## Recommended Flow
1. Build the ISO inside the Arch environment
2. Copy the generated build manifest out of that environment
3. Import it with `scripts/import-build-manifest.ps1`
4. Start the VM cycle with the imported manifest so the evidence chain stays linked

## Typical Contents
- original external manifest path
- imported manifest path under `status/builds/`
- reported build mode
- reported run label
- reported ISO path from the Arch-side record
