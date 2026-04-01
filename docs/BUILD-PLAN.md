# Build Plan

## Immediate Goal
Produce a first clean AhmadOS ISO that:
- boots in a VM
- reaches SDDM
- can enter a Plasma session
- has working basic networking

## Current Readiness
- bootloader scaffolding exists for GRUB, Syslinux, and systemd-boot paths
- the live initramfs now has a dedicated `archiso` preset
- live user creation and service enablement are handled in `customize_airootfs.sh`
- a staged Arch build script now supports `stable` and `login-test` modes
- a dedicated VM checklist exists for repeatable testing
- local and Arch-side profile validation now exist before the first serious build
- build manifests and VM test report scaffolding now exist for evidence capture
- an Arch bootstrap helper now prepares the first real build environment
- a live diagnostics exporter now exists for VM-test artifact collection
- test-session summaries now exist to link build, VM, and diagnostics evidence
- live smoke checks now exist to provide a quick post-boot health report
- diagnostics imports now exist to bring exported live-session evidence back into the repo

## Build Order
1. Finalize the stable archiso baseline
2. Build `stable` in a real Arch environment
3. Test `stable` in a VM
4. Build `login-test` to verify SDDM and manual session entry
5. Fix boot/session issues before deeper app work

## Testing Priorities
- boot reliability
- boot menu to kernel handoff
- graphical session start
- SDDM login path in `login-test` mode
- keyboard/mouse responsiveness
- network availability
- VM compatibility
- firstboot report generation
- build manifest and VM report traceability
- diagnostics bundle export after VM boot
- session-level build/test decision tracking
- live smoke-check validation after VM boot
- imported diagnostics traceability inside the repo
