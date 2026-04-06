# Lumina-OS Release Records

Store prepared release packages here.

## Intended Contents
- release manifest
- release notes draft
- checksum file
- release validation report
- a current release-evidence pointer
- a current release-readiness pointer
- a current release-control-center pointer
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
7. Review `status/releases/CURRENT-RELEASE-EVIDENCE.md`
8. Review `status/releases/CURRENT-RELEASE-READINESS.md`
9. Review `status/releases/CURRENT-RELEASE-CONTROL-CENTER.md`
10. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
11. Review the generated `release-manifest.md`
12. Review the generated `release-notes.md`
13. Confirm the linked cycle-chain audit reflects the intended run
14. Run `scripts/validate-github-release-context.ps1`
15. Run `scripts/publish-github-release.ps1` with the prepared manifest
16. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
17. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
