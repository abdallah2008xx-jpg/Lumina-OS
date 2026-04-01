# Lumina-OS Cycle Handoffs

Store generated handoff/runbook files here for real build and VM cycles.

## Purpose
- give one exact execution sheet for a real run
- keep the same `Run Label` from build to VM to release
- reduce operator mistakes during the first real Lumina-OS validation cycles

## Recommended Flow
1. Run `scripts/new-cycle-handoff.ps1`
2. Reuse the generated `Run Label` exactly
3. Follow the handoff from Windows prep to Arch build to VM cycle to release prep
4. Keep the handoff file with the rest of the status evidence for that run
