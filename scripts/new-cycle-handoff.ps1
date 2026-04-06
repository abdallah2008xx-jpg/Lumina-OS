param(
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$RunLabel = "",
    [string]$ReleaseVersion = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-SafeFileSegment {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unnamed"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\.-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

function Get-ModeFocus {
    param([string]$SelectedMode)

    if ($SelectedMode -eq "login-test") {
        return @(
            "- this run is centered on the real SDDM path and manual session entry",
            "- treat the login surface and manual Plasma entry as the primary acceptance gate"
        ) -join "`r`n"
    }

    return @(
        "- this run is centered on the autologin desktop path and first-session experience",
        "- treat Welcome, Update Center, runtime reports, and desktop polish as the primary acceptance gate"
    ) -join "`r`n"
}

function Get-ModeChecks {
    param([string]$SelectedMode)

    if ($SelectedMode -eq "login-test") {
        return @(
            "- SDDM appears with the Lumina-OS theme applied",
            "- username and password fields are readable and usable",
            "- session selector works and manual login reaches Plasma",
            "- login prompt feedback uses the correct info and error styling",
            "- post-login Welcome, Update Center, and diagnostics paths still work"
        ) -join "`r`n"
    }

    return @(
        "- autologin reaches Plasma without stalling",
        "- wallpaper, panel layout, and color scheme look applied",
        "- Welcome opens once and applies saved choices after closing",
        "- Update Center loads cached metadata and shows the selected channel clearly",
        "- firstboot report, smoke checks, and diagnostics export all work"
    ) -join "`r`n"
}

function Get-ModeReviewNotes {
    param([string]$SelectedMode)

    if ($SelectedMode -eq "login-test") {
        return @(
            "- confirm SDDM quality before treating the login path as acceptable",
            "- compare this run against the latest `stable` evidence before any public release decision",
            "- keep this mode release-focused only if the stable path is already healthy"
        ) -join "`r`n"
    }

    return @(
        "- use this run as the main desktop-first evidence chain for release readiness",
        "- only move to release preparation if blockers, readiness, and validation matrix all support it",
        "- record any user-visible polish issue here before packaging the ISO"
    ) -join "`r`n"
}

function Get-ReleaseGuard {
    param([string]$SelectedMode)

    if ($SelectedMode -eq "login-test") {
        return @(
            "Use this only if the manual-login evidence is part of the release decision.",
            'For most public releases, `login-test` is supporting evidence and `stable` remains the main packaging path.'
        ) -join "`r`n"
    }

    return @(
        "Use this after the stable cycle is acceptable and the evidence chain is complete.",
        "This is the normal path for the first public Lumina-OS ISO package."
    ) -join "`r`n"
}

function Get-ExpectedEvidence {
    return @(
        '- build manifest under `status/builds/` with `Run Label: __RUN_LABEL__`',
        '- VM report under `status/vm-tests/` with the same label',
        '- session summary and session audit linked to the same label',
        '- readiness, validation matrix, and cycle-chain audit reviewed after finishing the cycle',
        '- release evidence audit showing soft and strict gate state for the same label before packaging',
        '- release candidate summary and release manifest using the same label if packaging begins'
    ) -join "`r`n"
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeVmType = $VmType.ToLowerInvariant().Replace(" ", "-")
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
    "$timeStamp-$Mode-$safeVmType"
}
else {
    $RunLabel.Trim()
}

$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$handoffDir = Join-Path $RepoRoot ("status\cycle-handoffs\" + $dateStamp)
$handoffPath = Join-Path $handoffDir ("cycle-handoff-" + $safeRunLabel + ".md")
$releaseVersionLine = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) { "not-recorded-yet" } else { $ReleaseVersion.Trim() }

New-Item -ItemType Directory -Force -Path $handoffDir | Out-Null

$template = @'
# Lumina-OS Cycle Handoff

- Created At: __CREATED_AT__
- Mode: __MODE__
- VM Type: __VM_TYPE__
- Firmware: __FIRMWARE__
- Run Label: __RUN_LABEL__
- Planned Release Version: __RELEASE_VERSION__

## Goal
- carry one exact `Run Label` from build to VM validation to release preparation
- avoid latest-file guessing during the first real Lumina-OS cycle

## Mode Focus
__MODE_FOCUS__

## Step 1: Windows Preparation
Run this from the repo root in Windows:

    powershell -ExecutionPolicy Bypass -File .\scripts\validate-profile.ps1
    .\scripts\build-iso.ps1 -Mode __MODE__ -RunLabel __RUN_LABEL__

## Step 2: Arch Build
Run this from the repo root inside the Arch build environment:

    ./scripts/bootstrap-arch-build-env.sh --install
    ./scripts/build-iso-arch.sh --mode '__MODE__' --run-label '__RUN_LABEL__'

## Step 3: Start VM Cycle In Windows
After the ISO exists, start the evidence chain with the same label:

    .\scripts\start-vm-test-cycle.ps1 -Mode __MODE__ -VmType __VM_TYPE__ -Firmware __FIRMWARE__ -RunLabel __RUN_LABEL__

If the Arch build happened in a separate clone or VM, import its build manifest into this repo first:

    .\scripts\import-build-manifest.ps1 -ManifestPath "C:\Path\To\build-manifest.md"

If the ISO file is also copied back to Windows for later release prep, import that local ISO copy too:

    .\scripts\import-iso-artifact.ps1 -IsoPath "C:\Path\To\lumina-os.iso" -Mode __MODE__ -RunLabel __RUN_LABEL__

If both the manifest and ISO are copied back together in one handoff folder, import that folder instead:

    .\scripts\import-build-handoff.ps1 -HandoffPath "C:\Path\To\build-handoff-folder"

## Step 4: Inside The Booted ISO
Inside the live session, verify:
__MODE_CHECKS__

Then export diagnostics from inside Lumina-OS:
- App launcher entry: `Export Lumina-OS Diagnostics`
- Expected output folder: `~/Documents/Lumina-OS Diagnostics/`

## Step 5: Finish VM Cycle In Windows
Replace the bundle path with the exported diagnostics file or extracted folder:

    .\scripts\finish-vm-test-cycle.ps1 -BundlePath "C:\Path\To\Lumina-OS-Diagnostics" -Mode __MODE__ -VmType __VM_TYPE__ -Firmware __FIRMWARE__ -RunLabel __RUN_LABEL__

## Step 6: Review Evidence
Review these files after finish:
- `status/readiness/CURRENT-READINESS.md`
- `status/validation-matrix/CURRENT-VALIDATION-MATRIX.md`
- `status/blockers/CURRENT-BLOCKERS.md`
- matching files under `status/builds/`, `status/vm-tests/`, `status/test-sessions/`, and `status/test-session-audits/`

Mode-specific review notes:
__MODE_REVIEW_NOTES__

## Step 7: Audit Release Evidence
__RELEASE_GUARD__

    .\scripts\audit-release-evidence.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel __RUN_LABEL__

## Step 8: Prepare Release Candidate
Use the same label and keep evidence exact if possible:

    .\scripts\prepare-release-candidate.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel __RUN_LABEL__

For a strict release gate:

    .\scripts\prepare-release-candidate.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel __RUN_LABEL__ -RequireExactEvidenceRunLabel

## Step 9: Audit Release Readiness
Use this after candidate prep to get a direct go/no-go summary:

    .\scripts\audit-release-readiness.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel __RUN_LABEL__

## Step 10: Review Candidate Output
Review these files before publishing:
- `status/release-candidates/CURRENT-RELEASE-CANDIDATE.md`
- generated `release-evidence-audit.md` under `status/releases/`
- generated `release-readiness-audit.md` under `status/releases/`
- generated `release-validation.md` under `status/releases/`

## Step 11: Publish GitHub Release
Use this only after the validation report passes and the token is available:

    .\scripts\publish-github-release.ps1 -ReleaseManifestPath "C:\Path\To\release-manifest.md"

## Evidence Targets
__EXPECTED_EVIDENCE__

## Notes
- If you repeat the same mode again, prefer generating a fresh handoff with a new label.
- Keep the exact same label across build, VM, and release steps.
- Do not publish a release from a different label than the one you validated.
'@

$content = $template.Replace("__CREATED_AT__", (Get-Date -Format s)).
    Replace("__MODE__", $Mode).
    Replace("__VM_TYPE__", $VmType).
    Replace("__FIRMWARE__", $Firmware).
    Replace("__RUN_LABEL__", $resolvedRunLabel).
    Replace("__RELEASE_VERSION__", $releaseVersionLine).
    Replace("__MODE_FOCUS__", (Get-ModeFocus -SelectedMode $Mode)).
    Replace("__MODE_CHECKS__", (Get-ModeChecks -SelectedMode $Mode)).
    Replace("__MODE_REVIEW_NOTES__", (Get-ModeReviewNotes -SelectedMode $Mode)).
    Replace("__RELEASE_GUARD__", (Get-ReleaseGuard -SelectedMode $Mode)).
    Replace("__EXPECTED_EVIDENCE__", (Get-ExpectedEvidence))

Set-Content -Path $handoffPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $handoffPath
}
else {
    Write-Host "Created Lumina-OS cycle handoff:"
    Write-Host $handoffPath
}
