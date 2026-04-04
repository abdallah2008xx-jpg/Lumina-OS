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
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-$Mode-$safeVmType" } else { $RunLabel.Trim() }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reportDir = Join-Path $RepoRoot ("status\vm-tests\" + $dateStamp)
$reportName = "vm-test-$safeRunLabel.md"
$reportPath = Join-Path $reportDir $reportName

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$isoDisplay = if ([string]::IsNullOrWhiteSpace($IsoPath)) { "not-recorded-yet" } else { $IsoPath }

$content = @"
# Lumina-OS VM Test Report

- Date: $dateStamp
- Run Label: $resolvedRunLabel
- Mode: $Mode
- VM Type: $VmType
- Firmware: $Firmware
- ISO Path: $isoDisplay
- Tester: pending

## Boot Path
- [ ] Boot menu appears
- [ ] Selected entry starts correctly
- [ ] Kernel handoff completes
- [ ] No freeze or black screen during live boot

## Login Path
- [ ] Stable mode reaches Plasma autologin
- [ ] Login-test mode shows the SDDM theme
- [ ] Manual login reaches Plasma when applicable

## Lumina-OS Runtime
- [ ] Welcome opens for the live user
- [ ] Welcome changes apply after the app closes
- [ ] Update Center opens with cached release metadata
- [ ] Firstboot report is generated at `~/.local/state/ahmados/firstboot-report.md`
- [ ] Firstboot report launcher opens successfully

## Plasma Session
- [ ] Wallpaper is branded and renders correctly
- [ ] Panel layout matches the selected Lumina-OS layout
- [ ] Color scheme looks applied correctly
- [ ] Konsole opens
- [ ] Dolphin opens
- [ ] Input is responsive

## Networking And Guest Behavior
- [ ] NetworkManager is active
- [ ] Networking can be configured
- [ ] Browser access works if internet is available
- [ ] Guest display behavior is acceptable
- [ ] No oversized desktop or scrollbars are visible in the VM window
- [ ] Display resize or fallback behavior is recorded when using VirtualBox

## Findings
- none yet

## Blockers
- none yet

## Notes
- add firstboot-report observations here
- add SDDM/theme observations here
- add regression notes here
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created VM test report:"
    Write-Host $reportPath
}
