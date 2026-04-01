# Build Notes

This profile is the first clean Lumina-OS rebuild baseline.

Goals:
- boot reliably in VM
- reach a working KDE graphical session
- avoid fragile custom branding during early milestones
- add branding only after stable boot/login is proven

Current baseline includes:
- explicit GRUB, systemd-boot, and Syslinux menu entries
- a minimal `mkinitcpio` archiso preset
- build-time live-user and service setup via `customize_airootfs.sh`
- a real Lumina-OS SDDM theme and Plasma live-session defaults
