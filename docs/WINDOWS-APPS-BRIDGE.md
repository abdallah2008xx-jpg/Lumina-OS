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
- a launch-results sync layer that imports shared guest results back into Lumina workflow state so staged EXE requests are no longer a blind queue
- a launch-session layer that chains broker, warm-start, and results-sync together when the user simply clicks a Windows launch file
- a guest-onboarding layer that turns the generated guest agent pack into a concrete Windows-side install checklist and success gate
- an app-registration layer that turns installed app sets into named manifests so later proof passes and launch flows target known apps instead of raw setup steps
- an app-launcher-pack layer that turns registered apps into concrete launchers instead of leaving them as manifests only
- a registered-app launch layer that stages named app requests through the Windows workspace instead of relying only on raw `.exe` clicks
- an app-surfaces layer that indexes known registered Windows apps as launchable Lumina-side surfaces
- a registered-app picker layer that lets Lumina choose one known app and dry-run the named launch path without relying on a raw file click
- a guest-app-discovery layer that generates a Windows-side discovery pass for the registered app set
- an app-manifest-hydration layer that fills registered app manifests with real launch targets from guest-side discovery results
- an app-menu-export layer that promotes registered Windows apps into visible Lumina menu entries instead of keeping them buried in workspace artifacts

## Current Limits

- Lumina now owns the `.exe` and `.msi` entry point on the desktop side.
- It can select a workflow, prepare a workspace, stage the launch request, and open the right VM tools.
- It can also generate the guest-side launch agent pack and a quiet warm-start path for the VM.
- It can now sync launch result files back into the Lumina workflow and mark whether a request is still pending or already consumed by the guest.
- Desktop-side `.exe` clicks now enter a full launch session flow instead of stopping at the raw broker layer.
- It can now define the exact Windows-side onboarding step required before a staged request can honestly become hands-free.
- It can now generate named app manifests for each workflow so installed Windows apps become trackable entities inside Lumina.
- It can now generate registered-app launchers that target known Windows app manifests rather than relying only on raw `.exe` clicks.
- It can now stage named registered-app launch requests through the same Lumina workflow path instead of treating every Windows app launch like an anonymous file.
- It can now index those known apps into a dedicated app-surfaces layer instead of scattering them across raw files and reports.
- It can now dry-run one known registered app through a picker flow before the workflow is considered truly hands-free.
- It can now prepare a Windows-side discovery pass that searches for installed app targets instead of relying only on manual manifest edits.
- It can now hydrate the registered app manifests from shared guest-side discovery results when those results exist.
- It can now export named Windows app launchers into the Lumina application menu after the manifests and app surfaces are ready.
- The guest still needs that generated launch agent installed once before staged requests become truly hands-free.
- Lumina still does not project true seamless Windows app windows into KDE yet; the result path is tracked honestly through reports and workflow state.

## Future Target

The long-term target is a hidden background Windows workspace for creator apps, plus a separate gaming performance path, while keeping Lumina as the only visible desktop shell.

## Out Of Scope

- anti-cheat bypass
- VM hiding to evade software policy
- false claims that every Windows app will work on every machine with zero latency
