# Lumina-OS Update Center Implementation

## Purpose
Document the real Update Center shell that now reads release metadata from cached JSON instead of hardcoding release cards in QML.

## Implemented Now
- QML application at `archiso-profile/airootfs/usr/share/ahmados/update-center/Main.qml`
- launcher script at `archiso-profile/airootfs/usr/local/bin/ahmados-update-center`
- metadata refresh script at `archiso-profile/airootfs/usr/local/bin/ahmados-refresh-release-metadata`
- release-source config at `archiso-profile/airootfs/etc/ahmados-release.conf`
- bundled fallback metadata at `archiso-profile/airootfs/usr/share/ahmados/update-center/releases.json`
- desktop launcher at `archiso-profile/airootfs/usr/share/applications/ahmados-update-center.desktop`

## Runtime Path
- the app uses `qmlscene6`
- the launcher refreshes local metadata before the QML surface opens
- metadata is cached under `~/.cache/ahmados/update-center/`
- the QML layer reads both release data and status metadata from the cache
- the foreground channel shown in Update Center follows the saved Welcome selection in `~/.config/ahmados/welcome.conf`
- GitHub is now the preferred configured source, with a bundled fallback kept in place until real releases exist

## Current Scope
- metadata-backed release cards
- bundled fallback metadata with an easy path to GitHub Releases later
- installed-version and last-check summary
- foreground release-channel awareness
- recovery-risk messaging
- structured `loading`, `empty`, and `error` states inside the QML surface
- clearer saved-channel wording and match hints on release cards
- better channel ordering for normal-user reading, with `stable` foregrounded first
- cache-status reporting for requested source, active source, release count, and fallback reason

## Current Limitation
- the configured source can point to GitHub now, but the app still falls back to bundled metadata until the first real releases exist
- the app does not install packages or releases yet
- the reload button refreshes the local cache view, while network refresh currently happens at launch time
- rollback, history, and restart orchestration still belong to later passes
- package actions still remain intentionally absent until the first real ISO validation is complete

## Next Logical Steps
- validate the GitHub-backed path once the first release is published
- add explicit install, restart, and history behavior
- separate core-platform updates from Lumina-OS app-level updates
- validate metadata loading and channel behavior inside a built ISO
