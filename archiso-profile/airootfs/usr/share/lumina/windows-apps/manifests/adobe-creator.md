# Adobe Creator Workflow Manifest

## Linux-First Baseline

- Keep project files, exports, and references accessible from the main Lumina desktop.
- Use Linux-native browsers, file managers, and communication tools around the creator workflow.
- Treat Wine as a light experiment path only, not the promised final route for Adobe-heavy work.

## Windows Workspace Baseline

- Use one clean Windows VM for the whole Adobe workflow when possible.
- Install Creative Cloud inside that Windows workspace before the heavier Adobe apps.
- Keep the same Windows workspace for Photoshop, Illustrator, Premiere Pro, and After Effects so fonts, plugins, and caches stay consistent.

## First Session Checklist

- Confirm the Windows ISO is trusted and current.
- Prefer OVMF, TPM, and virtio where the workflow already supports them.
- Keep the VM disk on the fastest SSD path available.
- Validate Photoshop first, then Illustrator, then move into Premiere Pro or After Effects.

## Risks

- Premiere Pro and After Effects care more about GPU, storage, and export performance than light creator apps do.
- Plugin-heavy creator setups should be stabilized in a normal VM path before any stronger passthrough promises.
