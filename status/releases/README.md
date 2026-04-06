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
4. Run `scripts/audit-release-readiness.ps1` to confirm the final go/no-go state
5. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
6. Review the generated `release-manifest.md`
7. Review the generated `release-notes.md`
8. Confirm the linked cycle-chain audit reflects the intended run
9. Run `scripts/validate-github-release-context.ps1`
10. Run `scripts/publish-github-release.ps1` with the prepared manifest
11. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
12. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
