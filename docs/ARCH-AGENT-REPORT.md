# Lumina-OS: Archiso Architecture Review

## Executive summary
The rebuild is pointed in the right direction: Arch + Plasma + SDDM, minimal branding, and a stability-first live ISO goal. The current profile is a good skeleton, but it is **not yet build-ready** and still carries a few choices that can create the same kind of session instability you were trying to avoid.

The biggest themes:
- keep the live ISO as close to stock Arch/archiso behavior as possible
- remove duplicate or competing session start paths
- reduce package scope for the first reliable milestone
- stop shipping hand-copied system units unless absolutely necessary
- add explicit build/test gates so every ISO attempt is measurable

---

## What looks good already
- Clear product direction in `docs/ARCHITECTURE.md`
- Correct decision to keep branding light early on
- Sensible KDE/SDDM baseline
- X11-first live session strategy for VM testing
- Basic live user and NetworkManager groundwork already present

---

## Highest-priority problems found

### 1) Two graphical session entry paths exist
Current state:
- SDDM autologin is enabled in `etc/sddm.conf.d/autologin.conf`
- `home/live/.bash_profile` still tries to run `startplasma-x11` on tty1

Why this is risky:
- this recreates the exact class of â€œblack screen / conflicting startup pathâ€ problems that often happen in custom live ISOs
- tty autostart and display-manager autostart should not coexist in the first milestone

Recommendation:
- **keep SDDM as the only graphical entry path**
- replace `home/live/.bash_profile` with a plain shell profile, or remove the autostart logic entirely

---

### 2) Hand-copied systemd service files are fragile
Current state:
- custom copies of `display-manager.service`, `graphical.target.wants/sddm.service`, and `multi-user.target.wants/NetworkManager.service` are stored in `airootfs/etc/systemd/system`

Why this is risky:
- copied unit files drift from upstream package versions
- if Arch changes the service definition, the ISO can silently keep stale behavior
- enabling services by copying full unit definitions is heavier than needed

Recommendation:
- **do not vendor full upstream unit files unless you are intentionally modifying them**
- enable packaged services using symlinks or archiso customization steps, not duplicated full unit contents
- if you need overrides, place only drop-ins under `etc/systemd/system/<unit>.d/*.conf`

Preferred early baseline:
- keep packaged `sddm.service`
- keep packaged `NetworkManager.service`
- only add config drop-ins where Lumina-OS behavior truly differs

---

### 3) Package baseline is too broad for the first stability milestone
Current package list includes both:
- `qt5-wayland` and `qt6-wayland`
- `wayland`, `egl-wayland`, `xorg-*`
- guest tools for both VirtualBox and VMware
- extra desktop apps before session stability is proven

Why this is risky:
- bigger image, bigger failure surface
- more moving parts while debugging display/session issues
- first boot validation should prove display, networking, storage, input, and shell stability before feature growth

Recommendation:
Create a **strict phase-1 package baseline**.

### Recommended phase-1 package set
Keep:
- `base`
- `linux`
- `linux-firmware`
- `mkinitcpio`
- `archlinux-keyring`
- `sudo`
- `nano`
- `networkmanager`
- `grub`
- `syslinux`
- `mesa`
- `xorg-server`
- `xorg-xinit`
- `xorg-xwayland` (optional, but acceptable for Plasma compatibility)
- `plasma-desktop`
- `plasma-workspace`
- `sddm`
- `konsole`
- `dolphin`
- `plasma-nm`
- `plasma-pa`
- `firefox`
- `noto-fonts`
- `noto-fonts-emoji`
- `breeze`
- `breeze-gtk`
- `breeze-icons`
- `qqc2-breeze-style`

Move to phase 2 or make optional:
- `qt5-wayland` (likely unnecessary unless a specific Qt5 Wayland app needs it)
- `wayland`
- `qt6-wayland`
- `egl-wayland`
- `xorg-xrandr`
- `xorg-xsetroot`
- `vim`
- `ark`
- `spectacle`
- `inter-font`
- `ttf-dejavu`
- `ttf-liberation`
- `virtualbox-guest-utils`
- `open-vm-tools`
- `efibootmgr`
- `memtest86+`

Notes:
- VM tools are useful, but for an early universal live ISO they are not required to prove boot/session correctness
- add them back only after the base ISO reliably reaches desktop in at least one test VM and one bare-metal test

---

### 4) The profile is missing explicit build-readiness discipline
Current state:
- good docs exist, but the profile is still a scaffold
- there is no visible validation checklist tied to each ISO build attempt

Recommendation:
Adopt a hard gate for â€œbuild-readyâ€:

A profile is build-ready only when all are true:
1. `mkarchiso` completes with no manual fixes
2. ISO boots in UEFI VM
3. ISO boots in BIOS VM
4. SDDM appears consistently
5. Plasma session launches from SDDM autologin or manual login
6. Networking works through NetworkManager
7. shutdown/reboot/log out work cleanly
8. journal contains no repeating crash loop for `sddm`, `plasmashell`, or GPU stack

---

## Concrete architecture recommendations

### A) Treat the live ISO as a product-specific variant of Arch releng, not a custom OS yet
For the first milestone, Lumina-OS should behave like:
- Arch ISO boot pipeline
- Lumina-OS branding/config layer on top

That means:
- minimal changes to bootloader behavior
- minimal changes to display manager behavior
- no custom tty fallback launchers
- no aggressive firstboot logic

This is the fastest route to a trustworthy base.

---

### B) Split packages into tiers
Recommended structure:
- `packages.base` â†’ required for all builds
- `packages.desktop` â†’ Plasma session
- `packages.branding` â†’ fonts/themes/icons/wallpapers
- `packages.vm` â†’ guest packages only for VM-oriented test images
- generated `packages.x86_64` for the selected build flavor

Why this helps:
- easier debugging
- smaller change sets
- clear difference between â€œmust bootâ€ and â€œnice to haveâ€

If you want to stay simple, keep one final `packages.x86_64` file but annotate it with sections matching those tiers.

---

### C) Use override files, not copied units
Replace full copies with one of these patterns:
- symlink packaged services into wanted targets
- use `etc/systemd/system/sddm.service.d/*.conf` for Lumina-OS-specific overrides
- use `etc/systemd/system.conf.d/*.conf` only if system-level tuning is truly needed

This keeps the ISO closer to upstream and reduces maintenance burden.

---

### D) Keep X11 as milestone-1 default, but design for later dual-session support
Current direction is correct.

Recommendation:
- milestone 1: `plasmax11`
- milestone 2: add Wayland session as non-default test target
- milestone 3: evaluate whether Wayland becomes the default on supported hardware

Do not try to solve â€œperfect Wayland + perfect VM + custom brandingâ€ at the same time.

---

## Recommended file-level changes

### 1) `airootfs/home/live/.bash_profile`
Current file should be simplified.

Recommended result:
```bash
# Lumina-OS live user shell profile
# Keep graphical startup under SDDM only for milestone 1.
```

### 2) `airootfs/etc/systemd/system/display-manager.service`
### 3) `airootfs/etc/systemd/system/graphical.target.wants/sddm.service`
### 4) `airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service`
Recommended action:
- remove vendored full unit definitions
- replace with proper enablement method or only minimal overrides

### 5) `packages.x86_64`
Trim to a smaller milestone-1 set, then reintroduce extras only after the first stable ISO exists.

### 6) `profiledef.sh`
Keep current basic shape, but consider these future improvements after first successful build:
- verify whether both `uefi-ia32` targets are actually needed
- if you are not targeting 32-bit UEFI devices, drop IA32 boot modes to reduce complexity
- add version/channel naming discipline (`0.1.0-alpha1`, etc.) once builds start shipping

Practical recommendation now:
- for development, consider **x86_64 UEFI + BIOS only** unless you specifically need 32-bit UEFI support

---

## Build-readiness plan

### Phase 1 â€” Stabilize the live desktop path
Do now:
1. Remove tty-based Plasma autostart from `.bash_profile`
2. Stop copying full upstream service units
3. Trim package list to minimum viable desktop
4. Keep Breeze theme and stock SDDM behavior
5. Keep firstboot script as a no-op placeholder

Success criteria:
- reproducible ISO build
- SDDM appears reliably
- Plasma session starts reliably

### Phase 2 â€” Improve observability
Add:
- post-boot test checklist in `docs/BUILD-PLAN.md`
- log capture notes: `journalctl -b`, `systemctl status sddm`, `loginctl session-status`, `glxinfo -B` or equivalent if installed
- known-good VM matrix: VirtualBox, VMware, QEMU/virt-manager

Success criteria:
- every failed build gives clear evidence instead of guesswork

### Phase 3 â€” Controlled polish
Add back gradually:
- fonts beyond the minimum set
- guest tools per VM target
- wallpaper/branding assets
- custom SDDM theme only after stock Breeze remains stable across several boots

Success criteria:
- no regression in login, logout, reboot, or shutdown behavior

---

## Suggested test matrix
For each new ISO:

### Boot tests
- BIOS VM boot
- UEFI VM boot
- at least one cold boot and one reboot cycle

### Session tests
- reach SDDM
- login/autologin into Plasma X11
- open Konsole, Dolphin, Firefox
- connect networking through NetworkManager
- logout to SDDM and log back in

### Stability tests
- suspend can wait until later
- shutdown and reboot must work now
- inspect logs for GPU/session loops

---

## Bottom line
The rebuild is structurally promising, but the next smart move is not more customization. It is **less**.

For the first serious Lumina-OS ISO, aim for:
- stock archiso behavior
- stock SDDM service
- one graphical startup path only
- one tested desktop session only
- the smallest package set that still feels like a real product

If you do that, Lumina-OS gets a stable base you can safely make beautiful later instead of another hard-to-debug boot experiment.
