# Changelog

All notable changes to Lumina-OS should be recorded here.

This project follows a simple rule for now:
- `Unreleased` collects current work on `main`
- the first tagged release should happen only after a real build and VM validation cycle

## Unreleased

### Added
- Structured `archiso` profile and staged build workflow
- Real SDDM, Plasma, wallpaper, Welcome, and Update Center surfaces inside the live image
- Build/test evidence workflow with manifests, VM reports, diagnostics imports, audits, blockers, readiness, and validation matrix
- GitHub-hosted project baseline under the `Lumina-OS` repository
- Visible project and workflow branding aligned to `Lumina-OS`
- Release-package scaffolding for checksums, release notes drafts, and release manifests
- A single-owner execution plan after the former Mohammad UI/UX track was absorbed into the main flow
- GitHub release publishing automation via `scripts/publish-github-release.ps1`
- Release-package validation gating via `scripts/validate-release-package.ps1`
- Generated cycle handoffs via `scripts/new-cycle-handoff.ps1`
- Workflow smoke testing via `scripts/smoke-workflow-tools.ps1`

### Changed
- Live-system UI wording now presents the distro as `Lumina-OS`
- Build/test/report scripts now emit `Lumina-OS` branding in generated output
- Welcome now uses friendlier saved-choice labels, stronger apply summaries, and recommendation badges
- Update Center now exposes structured `loading`, `empty`, and `error` states with clearer channel wording
- SDDM now uses validation-oriented guidance and safer information-message coloring
- Update Center now prefers GitHub release metadata and records why bundled fallback metadata is used when needed
- GitHub publishing now validates evidence/readiness state before creating a release unless the gate is intentionally skipped
- Build manifests now carry the shared `Run Label` so build, VM, and release evidence can be linked directly

### Pending Before First Tagged Release
- First real `stable` build in Arch
- First real `login-test` build in Arch
- First VM evidence chain for both modes
- First published ISO, checksum, and release notes
