# Lumina-OS

A clean restart for a professional Linux distribution project.

## Vision

Build a polished Linux distribution with:
- the visual elegance of macOS
- the usability and familiarity of Windows
- a clean, stable, brandable KDE-based desktop
- a GitHub-driven release and update workflow
- room for OTA/package updates later

## Initial Direction

- Base: Arch Linux
- Desktop: KDE Plasma
- Display manager: SDDM
- Packaging/build approach: archiso + custom profile
- Distribution/update path: GitHub for source/releases first, package/update infrastructure later

## Phase 1 Goals

1. Build a clean project structure
2. Define product, technical, and release architecture
3. Create a first stable bootable ISO target
4. Avoid the current black-screen and over-customized boot issues
5. Introduce branding gradually after stability is proven

## Status

Project initialized on 2026-03-31.

Current project outputs include:
- archiso baseline work under `archiso-profile/`
- planning and UX specs under `docs/`
- brand direction under `branding/`
- local HTML interface prototypes under `prototypes/`
- real live-image theme assets for SDDM, Plasma, and wallpapers under `archiso-profile/airootfs/`
- staged Arch build/test workflow under `scripts/` and `docs/`
- real Lumina-OS Welcome app shell under `archiso-profile/airootfs/usr/share/ahmados/welcome/`
- real Lumina-OS Update Center shell under `archiso-profile/airootfs/usr/share/ahmados/update-center/`
- an `archinstall`-based installer launcher path under `archiso-profile/airootfs/usr/local/bin/lumina-installer`

## Collaboration

- Contributor workflow: `CONTRIBUTING.md`
- Current execution plan: `docs/TEAM-EXECUTION-PLAN.md`
- Changelog tracking: `CHANGELOG.md`
- First release gate: `docs/FIRST-RELEASE-CHECKLIST.md`
- Installer implementation notes: `docs/INSTALLER-IMPLEMENTATION.md`
- GitHub issue and PR templates live under `.github/`

## Project Snapshot

- Fast summary of what is done and what remains: `status/PROJECT-SUMMARY.md`
- Public/shareable project update: `status/SHAREABLE-UPDATE.md`
- Short shareable briefs: `status/SHAREABLE-BRIEF.md` and `status/SHAREABLE-BRIEF-AR.md`
- Current release-candidate state: `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
- Release package records: `status/releases/README.md`
