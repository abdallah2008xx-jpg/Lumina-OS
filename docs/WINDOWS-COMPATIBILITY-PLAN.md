# Lumina-OS Windows Compatibility Plan

## Goal
Make Lumina-OS excellent at running Windows software without pretending that every device or every game can use the same path.

## Supported Paths
- `Wine / Proton` for the default path across the widest range of hardware
- `Windows VM on KVM/libvirt` for Adobe apps, launchers, and difficult Windows-only tools
- `VFIO GPU passthrough` for advanced systems that support strong isolation and have passthrough-friendly hardware

## What Lumina-OS Will Not Do
- anti-cheat evasion
- VM hiding to bypass software policy
- false claims that every Windows app will run at full native performance on every machine

## Phase 1 Included In The ISO
- `qemu-full`
- `libvirt`
- `virt-manager`
- `edk2-ovmf`
- `dnsmasq`
- `bridge-utils`
- `swtpm`
- `iptables-nft`
- a live-session compatibility checker through `lumina-windows-compat-check`

## Machine Tiers
- `basic-proton-only`
  Use Wine and Proton first. VM passthrough is not ready yet.
- `windows-vm-ready`
  Windows VMs are practical for Adobe, installers, and toolchains.
- `single-gpu-experimental`
  VFIO groundwork exists, but the machine likely needs a careful single-GPU workflow.
- `full-passthrough-candidate`
  The machine looks like a strong candidate for Windows gaming or Adobe passthrough work.

## Practical Guidance
- the easiest passthrough systems are desktops with `iGPU + dGPU` or two GPUs
- single-GPU passthrough is possible on some hardware, but it is harder and less universal
- Looking Glass is a strong future direction, but it is not bundled in the base ISO path yet

## Next Engineering Steps
1. keep the live hardware checker accurate
2. add a guided VM creation path for Windows guests
3. add optional IOMMU boot guidance after fresh ISO validation
4. add a dedicated Adobe/Gaming VM setup guide
5. later evaluate optional Looking Glass integration as a follow-up track
