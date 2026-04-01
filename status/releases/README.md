# Lumina-OS Release Records

Store prepared release packages here.

## Intended Contents
- release manifest
- release notes draft
- checksum file
- release validation report
- evidence links to the tested build and VM cycle
- optional GitHub publish record after the release is created

## Recommended Flow
1. Finish the real build and VM evidence chain
2. Run `scripts/prepare-release-package.ps1`
3. Review the generated `release-manifest.md`
4. Review the generated `release-notes.md`
5. Run `scripts/validate-release-package.ps1`
6. Run `scripts/publish-github-release.ps1` with the prepared manifest
7. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
