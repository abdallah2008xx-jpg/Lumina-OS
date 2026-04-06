# Lumina-OS Release Records

Store prepared release packages here.

## Intended Contents
- release manifest
- release notes draft
- checksum file
- release validation report
- cycle-chain audit link for the selected run
- evidence links to the tested build and VM cycle
- optional GitHub publish record after the release is created

## Recommended Flow
1. Finish the real build and VM evidence chain
2. Run `scripts/audit-release-evidence.ps1` to inspect soft and strict evidence readiness
3. Run `scripts/prepare-release-candidate.ps1`
4. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
5. Review the generated `release-manifest.md`
6. Review the generated `release-notes.md`
7. Confirm the linked cycle-chain audit reflects the intended run
8. Run `scripts/validate-github-release-context.ps1`
9. Run `scripts/publish-github-release.ps1` with the prepared manifest
10. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
11. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
