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
2. Optionally create a shared evidence manifest with `scripts/new-release-evidence-pack.ps1`
3. Run `scripts/audit-release-evidence.ps1` to inspect soft and strict evidence readiness
4. Run `scripts/prepare-release-candidate.ps1`
5. Run `scripts/audit-release-readiness.ps1` to confirm the final go/no-go state
6. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
7. Review the generated `release-manifest.md`
8. Review the generated `release-notes.md`
9. Confirm the linked cycle-chain audit reflects the intended run
10. Run `scripts/validate-github-release-context.ps1`
11. Run `scripts/publish-github-release.ps1` with the prepared manifest
12. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
13. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
