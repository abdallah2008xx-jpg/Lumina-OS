# Lumina-OS Release Records

Store prepared release packages here.

## Intended Contents
- release manifest
- release notes draft
- checksum file
- release validation report
- a current release-readiness pointer
- cycle-chain audit link for the selected run
- evidence links to the tested build and VM cycle
- optional GitHub publish record after the release is created

## Recommended Flow
1. Finish the real build and VM evidence chain
2. Optionally create a shared evidence manifest with `scripts/new-release-evidence-pack.ps1`
3. Run `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"` to inspect soft and strict evidence readiness
4. Run `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
5. Run `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"` to confirm the final go/no-go state
6. Review `status/evidence-packs/CURRENT-EVIDENCE-PACK.md`
7. Review `status/releases/CURRENT-RELEASE-READINESS.md`
8. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
9. Review the generated `release-manifest.md`
10. Review the generated `release-notes.md`
11. Confirm the linked cycle-chain audit reflects the intended run
12. Run `scripts/validate-github-release-context.ps1`
13. Run `scripts/publish-github-release.ps1` with the prepared manifest
14. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
15. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
