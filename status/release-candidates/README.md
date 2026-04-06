# Lumina-OS Release Candidate Records

Keep the latest prepared release candidate state here.

## Intended Contents
- one summary per prepared candidate
- a current pointer to the latest candidate
- links to the release manifest, validation report, publish record, and tested evidence chain

## Recommended Flow
1. Finish a real labeled build and VM evidence chain
2. Run `scripts/audit-release-evidence.ps1` to inspect soft vs strict evidence readiness
3. Run `scripts/prepare-release-candidate.ps1`
4. Review `CURRENT-RELEASE-CANDIDATE.md`
5. Validate the GitHub publish context against the current candidate
6. If the candidate is clean, publish it with `scripts/publish-github-release.ps1`
7. Let `scripts/sync-release-candidate-status.ps1` refresh the candidate to `published`
8. Keep the candidate summary as the release trace even after publish
