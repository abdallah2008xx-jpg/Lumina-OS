# Lumina-OS Release Records

Store prepared release packages here.

## Intended Contents
- release manifest
- release notes draft
- checksum file
- evidence links to the tested build and VM cycle

## Recommended Flow
1. Finish the real build and VM evidence chain
2. Run `scripts/prepare-release-package.ps1`
3. Review the generated `release-manifest.md`
4. Review the generated `release-notes.md`
5. Upload the ISO and `SHA256SUMS.txt` to GitHub Releases
