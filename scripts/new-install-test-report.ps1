param(
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
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
$safeVmType = $VmType.ToLower().Replace(" ", "-")
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-$Mode-install-$safeVmType" } else { $RunLabel.Trim() }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reportDir = Join-Path $RepoRoot ("status\install-tests\" + $dateStamp)
$reportName = "install-test-$safeRunLabel.md"
$reportPath = Join-Path $reportDir $reportName

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$isoDisplay = if ([string]::IsNullOrWhiteSpace($IsoPath)) { "not-recorded-yet" } else { $IsoPath }

$content = @"
# Lumina-OS Install Test Report

- Date: $dateStamp
- Run Label: $resolvedRunLabel
- Mode: $Mode
- VM Type: $VmType
- Firmware: $Firmware
- ISO Path: $isoDisplay
- Install Target: blank-vm-disk
- Installer Launcher: Install Lumina-OS.desktop
- Installer Command: /usr/local/bin/lumina-installer
- Tester: pending
- Overall Status: in-progress

## Pre-Install Checks
- [ ] ISO boots on the chosen blank-disk VM
- [ ] Desktop reaches Plasma successfully before installation
- [ ] Install Lumina-OS launcher is visible on the desktop
- [ ] Installer terminal opens without launcher errors

## Installer Flow
- [ ] archinstall starts successfully
- [ ] Target disk is detected correctly
- [ ] Partitioning completes without installer errors
- [ ] Base package installation completes
- [ ] Bootloader installation completes
- [ ] Installer reaches a clean completion message
- [ ] Live preflight report is captured
- [ ] Finalize report is written to the installed target

## First Boot After Install
- [ ] VM reboots from the installed disk instead of the ISO
- [ ] Installed system reaches the login/session path successfully
- [ ] Plasma starts on the installed system
- [ ] No immediate black screen or boot loop appears

## Installed Runtime Checks
- [ ] Networking is available or configurable
- [ ] System Settings opens
- [ ] Dolphin opens
- [ ] Konsole opens
- [ ] Wallpaper and core Lumina branding appear correctly
- [ ] Shutdown and reboot work from the installed session

## Findings
- none yet

## Blockers
- none yet

## Notes
- record partitioning choices here
- record installer warnings or package failures here
- record post-install first-boot observations here
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created install test report:"
    Write-Host $reportPath
}
