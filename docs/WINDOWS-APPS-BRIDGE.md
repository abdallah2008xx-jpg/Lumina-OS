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
- a workflow-profile entry point for broader use cases like Adobe, Office, and gaming launchers
- a Windows App Catalog that maps common app families to the right path for the current machine
- a guided Windows App Assistant that turns one chosen app into a concrete route instead of leaving the user with generic reports
- a workflow runbook layer that turns each broader profile into an actionable starter plan
- a workspace bootstrap layer that creates Lumina-side folders, checklists, and naming conventions for the chosen workflow
- a tracked workflow state layer that records where the user is inside the selected Windows workflow
- a workflow recipe layer that turns each selected profile into a repeatable daily launch and shutdown rhythm
- a workflow hub layer that shows the current phase, the next recommended move, and the relevant reports from one entry point
- a workspace action-pack layer that generates ready-to-use helper scripts inside each workflow workspace
- a hidden session-start prep step that warms the Windows Apps path without opening an extra desktop

## Future Target

The long-term target is a hidden background Windows workspace for creator apps, plus a separate gaming performance path, while keeping Lumina as the only visible desktop shell.

## Out Of Scope

- anti-cheat bypass
- VM hiding to evade software policy
- false claims that every Windows app will work on every machine with zero latency
