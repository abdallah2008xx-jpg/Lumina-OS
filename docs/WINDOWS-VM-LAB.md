# Lumina Windows VM Lab

Lumina-OS now exposes a first user-facing Windows VM path inside the live system. This is not a fake "run every Windows app by magic" claim. It is a practical bridge that starts from real hardware checks and points the user toward the correct path for their machine.

## What Exists Now

- `lumina-windows-compat-check` classifies the machine into a safe compatibility tier.
- `lumina-windows-vm-lab` turns that compatibility result into a quickstart report and opens `virt-manager` automatically on machines that are ready for a normal Windows VM path.
- The live image includes the first virtualization stack baseline:
  - `qemu-full`
  - `libvirt`
  - `virt-manager`
  - `edk2-ovmf`
  - `swtpm`
  - `dnsmasq`
  - bridge support through the standard `iproute2` tooling from the Arch base layer

## Supported User Story

1. Boot Lumina-OS.
2. Open `Lumina Windows VM Lab`.
3. Review the compatibility report and the lab report.
4. If the machine is `windows-vm-ready` or better, let the launcher open `virt-manager`.
5. Create a normal Windows VM first.
6. Use that VM for Adobe, launchers, office tools, and hard-to-port software before attempting any passthrough work.

## Why This Matters

This gives Lumina-OS a real Windows software bridge without lying about universality:

- mainstream hardware gets a normal Windows VM path
- stronger hardware can grow toward passthrough later
- weaker hardware still gets a clear Proton and Wine recommendation

## Not Included Yet

- a fully guided VM creation wizard
- bundled Windows images or drivers
- Looking Glass integration
- polished VFIO passthrough automation
- any anti-cheat evasion or VM hiding work

## Next Engineering Step

The next step after this lab launcher is a guided VM creation assistant that pre-fills a recommended OVMF + TPM + storage template for Lumina-OS.
