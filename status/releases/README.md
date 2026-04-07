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
- a current release-execution pointer
- a generated release-validation runbook for the current pass
- a generated release-validation workboard for the current pass
- a generated release-validation action pack for the current pass
- a current evidence-session pointer from `status/evidence-packs/`
- cycle-chain audit link for the selected run
- evidence links to the tested build and VM cycle
- optional GitHub publish record after the release is created

## Recommended Flow
1. Finish the real build and VM evidence chain
2. Optionally create a shared evidence manifest with `scripts/new-release-evidence-pack.ps1`
3. Run `scripts/audit-release-evidence.ps1 -EvidencePackPath "<path-to-pack>"` to inspect soft and strict evidence readiness
4. Run `scripts/prepare-release-candidate.ps1 -EvidencePackPath "<path-to-pack>"`
5. Run `scripts/audit-release-readiness.ps1 -EvidencePackPath "<path-to-pack>"` to confirm the final go/no-go state
6. Optionally start one combined pass with `scripts/start-release-validation-pass.ps1`
7. After evidence updates, refresh the combined pass with `scripts/sync-release-validation-pass.ps1 -ExecutionPath "<path-to-release-validation-pass>"`
8. Review `status/releases/CURRENT-RELEASE-EXECUTION.md`
   - it now shows the current execution gate, the next missing evidence target, and the progress for that report
9. Review the generated `release-validation-runbook-*.md`
10. Review the generated `release-validation-workboard-*.md` for the direct login-test, install, and hardware report paths and statuses
11. Review the generated `release-validation-actions-*/README.md` when you want direct helper scripts for open/sync/audit/RC
   - it now includes `00-run-next-step.ps1` for the next practical release-validation action
12. Review `status/evidence-packs/CURRENT-EVIDENCE-SESSION.md`
   - it now includes the evidence-session action pack plus the direct next action path and launcher
13. Review `status/evidence-packs/CURRENT-EVIDENCE-PACK.md`
14. Review `status/releases/CURRENT-RELEASE-EVIDENCE.md`
15. Review `status/releases/CURRENT-RELEASE-READINESS.md`
16. Review `status/releases/CURRENT-RELEASE-CONTROL-CENTER.md`
   - it now shows `Evidence Ready Count`, `Evidence Checklist Progress`, the evidence-session action pack, and the next evidence action from one place
17. Use `scripts/open-next-release-action.ps1` when you want one launcher that resolves the next practical release-validation step from the current execution/control state
18. Review `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
19. Review the generated `release-manifest.md`
20. Review the generated `release-notes.md`
21. Confirm the linked cycle-chain audit reflects the intended run
22. Run `scripts/validate-github-release-context.ps1`
23. Run `scripts/publish-github-release.ps1` with the prepared manifest
24. Confirm `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md` now shows the published state
25. Verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
