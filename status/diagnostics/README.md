# AhmadOS Diagnostics Records

Store imported diagnostics bundles here after exporting them from a live ISO session.

## Recommended Flow
1. Export diagnostics from inside AhmadOS
2. Import the bundle with `scripts/import-diagnostics-bundle.ps1`
3. Link the resulting import manifest from `status/test-sessions/`

## Typical Contents
- summary from inside the live session
- firstboot report
- smoke-check report
- update metadata cache
- network and session command output
