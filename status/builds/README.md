# Lumina-OS Build Records

Store build manifests here after real Arch-side ISO builds.

## Intended Contents
- build mode
- run label
- timestamp
- output ISO path
- checksum
- quick next-verification notes

## Current Workflow
- `scripts/build-iso-arch.sh` now writes a manifest here after `mkarchiso` finishes
- the build manifest now carries the same `Run Label` that should be reused during the VM cycle and release flow
- keep these records even when the ISO itself lives outside the repo
- if a real Arch build happens in another clone, `scripts/import-build-manifest.ps1` can bring that manifest back here before the VM cycle begins
