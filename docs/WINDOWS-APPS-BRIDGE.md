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
- a next-action launcher that opens or runs the most sensible step for the current workflow state
- a VM template layer that defines a concrete Windows workspace shape before the actual VM gets created
- a VM creation starter layer that turns the VM template into paths, env files, checklists, and a starter command skeleton
- a VM post-create layer that guides the first boot, VirtIO, share validation, and clean-snapshot stage after the VM exists
- an app-install starter layer that turns each workflow profile into a first-pass software install plan instead of leaving app setup ad-hoc
- a workflow proof-pass layer that verifies real launch/save/export behavior before a workflow is considered genuinely usable
- a hidden session-start prep step that warms the Windows Apps path without opening an extra desktop
- an interactive onboarding layer that replaces reading multiple reports with one guided kdialog-based flow
- a VM launcher layer that creates a real Windows VM with one command instead of requiring manual virt-install execution
- a VM runner layer that manages daily VM operations (start, stop, connect, snapshot) from one entry point
- an auto-configure layer that checks VM networking, shares, and snapshots and offers to mark the VM as configured
- an EXE launch broker that captures `.exe` and `.msi` clicks, selects the right workflow, and stages the launch into the matching Lumina workspace
- default MIME handling that routes Windows launch files into the Lumina broker instead of treating them like stray binaries
- a staged launch-request layer that copies unsupported Windows launch files into the workflow share and opens the right VM path honestly
- a guest-agent pack that generates the Windows-side launch consumer and startup helper for the selected workflow
- a warm-start VM layer that starts the Windows workspace quietly and reports whether pending launch requests are ready to be consumed

## Current Limits

- Lumina now owns the `.exe` and `.msi` entry point on the desktop side.
- It can select a workflow, prepare a workspace, stage the launch request, and open the right VM tools.
- It can also generate the guest-side launch agent pack and a quiet warm-start path for the VM.
- The guest still needs that generated launch agent installed once before staged requests become truly hands-free.

## Future Target

The long-term target is a hidden background Windows workspace for creator apps, plus a separate gaming performance path, while keeping Lumina as the only visible desktop shell.

## Out Of Scope

- anti-cheat bypass
- VM hiding to evade software policy
- false claims that every Windows app will work on every machine with zero latency
