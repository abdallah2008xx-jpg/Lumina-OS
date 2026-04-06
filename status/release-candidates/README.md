# Lumina-OS Release Candidate Records

Keep the latest prepared release candidate state here.

## Intended Contents
- one summary per prepared candidate
- a current pointer to the latest candidate
- links to the release manifest, validation report, publish record, and tested evidence chain

## Recommended Flow
1. Finish a real labeled build and VM evidence chain
2. Optionally create a shared evidence manifest with `scripts/new-release-evidence-pack.ps1`
3. Run `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"` to inspect soft vs strict evidence readiness
4. Run `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
5. Run `scripts/audit-release-readiness.ps1` to confirm the final go/no-go state
6. Review `status/evidence-packs/CURRENT-EVIDENCE-PACK.md`
7. Review `CURRENT-RELEASE-CANDIDATE.md`
8. Validate the GitHub publish context against the current candidate
9. If the candidate is clean, publish it with `scripts/publish-github-release.ps1`
10. Let `scripts/sync-release-candidate-status.ps1` refresh the candidate to `published`
11. Keep the candidate summary as the release trace even after publish
