param(
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$RunLabel = "",
    [string]$ReleaseVersion = "",
    [string]$IsoPath = "",
    [string]$DeviceLabel = "real-device",
    [string]$BootSource = "live-usb-or-installed-disk",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-MetadataValue {
    param(
        [string]$Content,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return ""
    }

    $pattern = "(?m)^- " + [regex]::Escape($Label) + ": (.+)$"
    $match = [regex]::Match($Content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return ""
}

function Get-RecordedValue {
    param(
        [string]$Content,
        [string]$Label,
        [string]$DefaultValue = "not-recorded-yet"
    )

    $value = Get-MetadataValue -Content $Content -Label $Label
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }

    return $value
}

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

$handoffScript = Join-Path $PSScriptRoot "new-cycle-handoff.ps1"
$evidenceSessionScript = Join-Path $PSScriptRoot "start-release-evidence-session.ps1"
$syncValidationPassScript = Join-Path $PSScriptRoot "sync-release-validation-pass.ps1"

foreach ($requiredScript in @($handoffScript, $evidenceSessionScript, $syncValidationPassScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

$handoffPath = & $handoffScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -RunLabel $RunLabel `
    -ReleaseVersion $ReleaseVersion `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$evidenceSessionPath = & $evidenceSessionScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $IsoPath `
    -ReleaseVersion $ReleaseVersion `
    -DeviceLabel $DeviceLabel `
    -BootSource $BootSource `
    -RunLabel $RunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$resolvedHandoffPath = (Resolve-Path $handoffPath).Path
$resolvedEvidenceSessionPath = (Resolve-Path $evidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$runLabelValue = Get-RecordedValue -Content $sessionContent -Label "Run Label"
$releaseVersionValue = Get-RecordedValue -Content $sessionContent -Label "Release Version"
$evidencePackPath = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack"
$runbookPath = Get-RecordedValue -Content $sessionContent -Label "Runbook Path"
$currentEvidenceSessionPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"
$currentReleaseControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$safeRunLabel = Get-SafeFileSegment $runLabelValue
$executionDir = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$executionPath = Join-Path $executionDir ("release-validation-pass-" + $safeRunLabel + ".md")

New-Item -ItemType Directory -Force -Path $executionDir | Out-Null

$content = @"
# Lumina-OS Release Validation Pass

- Created At: $(Get-Date -Format s)
- Synced At: not-recorded-yet
- Execution State: ready-to-execute
- Run Label: $runLabelValue
- Release Version: $releaseVersionValue
- Mode: $Mode
- VM Type: $VmType
- Firmware: $Firmware
- Cycle Handoff: $resolvedHandoffPath
- Evidence Session: $resolvedEvidenceSessionPath
- Evidence Pack: $evidencePackPath
- Runbook Path: $runbookPath
- Execution Runbook Path: not-recorded-yet
- Workboard Path: not-recorded-yet
- Current Evidence Session: $(if (Test-Path $currentEvidenceSessionPath) { $currentEvidenceSessionPath } else { "not-recorded-yet" })
- Current Release Control Center: $(if (Test-Path $currentReleaseControlCenterPath) { $currentReleaseControlCenterPath } else { "not-recorded-yet" })

## Practical Order
1. Follow the cycle handoff for the build and VM validation path:
   $resolvedHandoffPath
2. Use the evidence session to keep login-test, install, and hardware evidence on the same run label:
   $resolvedEvidenceSessionPath
3. After evidence updates, refresh this validation pass with:
   .\scripts\sync-release-validation-pass.ps1 -ExecutionPath "$executionPath" -ReleaseVersion "$releaseVersionValue"
4. Review the current evidence-session and control-center pointers before RC prep.

## Goal
- start one real release-focused validation pass from a single entry point
- keep handoff, evidence session, evidence pack, and control center aligned on one run label
"@

Set-Content -Path $executionPath -Value $content -Encoding UTF8

$null = & $syncValidationPassScript `
    -ExecutionPath $executionPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $executionPath
}
else {
    Write-Host "Started release validation pass:"
    Write-Host $executionPath
}
