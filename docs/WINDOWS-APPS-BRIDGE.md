# Lumina Windows Apps Bridge

The product goal is simple: Windows software should feel like it belongs to Lumina-OS, not like the user is juggling two desktops.

## Experience Goal

- one desktop
- one launcher
- one taskbar
- one file flow
- no "open a VM first" feeling for normal creator workflows

## Product Language

User-facing surfaces should talk about:

- `Windows Apps`
- `Creator Mode`
- `Performance Mode`
- `Studio Mode`

They should not force users to think in terms of:

- raw virtualization
- VFIO internals
- libvirt plumbing
- guest consoles

## Technical Reality

Under the hood, Lumina-OS can still use:

- Wine or Proton
- a background Windows VM
- a stronger passthrough path on supported hardware

But the visible workflow should be Lumina-first.

## Current Phase

The current phase adds:

- a hardware compatibility checker
- a Windows VM Lab for advanced setup work
- a user-facing `Lumina Windows Apps` entry point that frames the experience in product language instead of engineering language
- a Windows App Catalog that maps common app families to the right path for the current machine
- a guided Windows App Assistant that turns one chosen app into a concrete route instead of leaving the user with generic reports
- a hidden session-start prep step that warms the Windows Apps path without opening an extra desktop

## Future Target

The long-term target is a hidden background Windows workspace for creator apps, plus a separate gaming performance path, while keeping Lumina as the only visible desktop shell.

## Out Of Scope

- anti-cheat bypass
- VM hiding to evade software policy
- false claims that every Windows app will work on every machine with zero latency
