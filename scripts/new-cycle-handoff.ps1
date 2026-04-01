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
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

## Step 4: Inside The Booted ISO
Inside the live session, verify:
- boot path is stable
- Plasma or SDDM behavior matches the selected mode
- Welcome, Update Center, firstboot report, and smoke checks behave correctly

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

## Step 7: Prepare Release Package
Use this only after the cycle is acceptable.

    .\scripts\prepare-release-package.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel __RUN_LABEL__

## Step 8: Validate Release Package
Replace the manifest path with the generated file under `status/releases/`:

    .\scripts\validate-release-package.ps1 -ReleaseManifestPath "C:\Path\To\release-manifest.md"

## Step 9: Publish GitHub Release
Use this only after the validation report passes and the token is available:

    .\scripts\publish-github-release.ps1 -ReleaseManifestPath "C:\Path\To\release-manifest.md"

## Evidence Targets
- Build manifest should include `Run Label: __RUN_LABEL__`
- VM report should include `Run Label: __RUN_LABEL__`
- Session summary should include `Run Label: __RUN_LABEL__`
- Release manifest should include `Run Label: __RUN_LABEL__`

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
    Replace("__RELEASE_VERSION__", $releaseVersionLine)

Set-Content -Path $handoffPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $handoffPath
}
else {
    Write-Host "Created Lumina-OS cycle handoff:"
    Write-Host $handoffPath
}
