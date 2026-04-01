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

### Changed
- Live-system UI wording now presents the distro as `Lumina-OS`
- Build/test/report scripts now emit `Lumina-OS` branding in generated output

### Pending Before First Tagged Release
- First real `stable` build in Arch
- First real `login-test` build in Arch
- First VM evidence chain for both modes
- First published ISO, checksum, and release notes
