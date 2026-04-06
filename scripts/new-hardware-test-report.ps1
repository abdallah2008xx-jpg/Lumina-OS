param(
    [string]$DeviceLabel = "",
    [string]$Firmware = "UEFI-or-BIOS",
    [string]$BootSource = "live-usb-or-installed-disk",
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
$resolvedDeviceLabel = if ([string]::IsNullOrWhiteSpace($DeviceLabel)) { "real-device" } else { $DeviceLabel.Trim() }
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-$resolvedDeviceLabel-hardware" } else { $RunLabel.Trim() }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reportDir = Join-Path $RepoRoot ("status\hardware-tests\" + $dateStamp)
$reportName = "hardware-test-$safeRunLabel.md"
$reportPath = Join-Path $reportDir $reportName

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$content = @"
# Lumina-OS Hardware Test Report

- Date: $dateStamp
- Run Label: $resolvedRunLabel
- Device Label: $resolvedDeviceLabel
- Firmware: $Firmware
- Boot Source: $BootSource
- Runtime Report Command: /usr/local/bin/lumina-hardware-readiness-check --open
- Runtime Report Path: ~/.local/state/ahmados/hardware-readiness-report.md
- Tester: pending
- Overall Status: in-progress

## Live Boot
- [ ] System boots on the real device
- [ ] Plasma or the expected desktop path appears
- [ ] Display output is stable and correctly sized
- [ ] Input devices work

## Core Hardware
- [ ] Wi-Fi or Ethernet hardware is detected
- [ ] Network can connect if expected on this device
- [ ] Audio output works
- [ ] Graphics look stable
- [ ] Storage devices look correct
- [ ] Shutdown works
- [ ] Reboot works

## Portable Device Checks
- [ ] Battery state is detected if applicable
- [ ] Brightness keys work if applicable
- [ ] Sleep or suspend is tested if applicable

## Evidence
- [ ] Hardware readiness report is attached or summarized
- [ ] Screenshots added only if useful

## Findings
- none yet

## Blockers
- none yet

## Notes
- record device model here
- record Wi-Fi/audio/graphics observations here
- record any firmware or boot quirks here
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created hardware test report:"
    Write-Host $reportPath
}
