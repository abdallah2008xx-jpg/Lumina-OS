param(
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$RunLabel = "",
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
    $safe = [regex]::Replace($safe, "[^a-z0-9\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-login-test" } else { $RunLabel.Trim() }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reportDir = Join-Path $RepoRoot ("status\login-tests\" + $dateStamp)
$reportName = "login-test-$safeRunLabel.md"
$reportPath = Join-Path $reportDir $reportName
$isoDisplay = if ([string]::IsNullOrWhiteSpace($IsoPath)) { "not-recorded-yet" } else { $IsoPath }

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$content = @"
# Lumina-OS Login-Test Report

- Date: $dateStamp
- Run Label: $resolvedRunLabel
- Mode: login-test
- VM Type: $VmType
- Firmware: $Firmware
- ISO Path: $isoDisplay
- Tester: pending
- Overall Status: in-progress

## SDDM Presentation
- [ ] SDDM appears instead of autologin
- [ ] Theme renders without clipped text
- [ ] Inputs, labels, and buttons are readable
- [ ] Clock, header, and helper text scale correctly

## Manual Login Path
- [ ] Username field works
- [ ] Password field works
- [ ] Session selector is usable
- [ ] Manual login reaches Plasma
- [ ] Incorrect login feedback looks intentional and readable

## Post-Login Runtime
- [ ] Plasma session starts without black screen
- [ ] Welcome still opens when expected
- [ ] Update Center still opens
- [ ] Diagnostics export still works

## Evidence
- [ ] VM screenshots are attached or referenced if needed
- [ ] Session summary is linked or referenced
- [ ] Session audit is linked or referenced

## Findings
- none yet

## Blockers
- none yet

## Notes
- record SDDM spacing and scaling observations here
- record manual login quirks here
- record post-login regressions here
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created login-test report:"
    Write-Host $reportPath
}
