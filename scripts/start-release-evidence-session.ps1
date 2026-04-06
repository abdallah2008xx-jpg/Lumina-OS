param(
    [string]$EvidencePackPath = "",
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$ReleaseVersion = "",
    [string]$DeviceLabel = "real-device",
    [string]$BootSource = "live-usb-or-installed-disk",
    [string]$RunLabel = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

$newPackScript = Join-Path $PSScriptRoot "new-release-evidence-pack.ps1"
$runbookScript = Join-Path $PSScriptRoot "new-release-evidence-runbook.ps1"
$syncPackScript = Join-Path $PSScriptRoot "sync-release-evidence-pack.ps1"
$syncSessionStatusScript = Join-Path $PSScriptRoot "sync-release-evidence-session-status.ps1"
$syncControlCenterScript = Join-Path $PSScriptRoot "sync-release-control-center.ps1"

foreach ($requiredScript in @($newPackScript, $runbookScript, $syncPackScript, $syncSessionStatusScript, $syncControlCenterScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

$resolvedEvidencePackPath = ""
if ([string]::IsNullOrWhiteSpace($EvidencePackPath)) {
    $resolvedEvidencePackPath = & $newPackScript `
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
}
else {
    if (-not (Test-Path $EvidencePackPath)) {
        throw "Evidence pack path not found: $EvidencePackPath"
    }

    $resolvedEvidencePackPath = & $syncPackScript `
        -EvidencePackPath $EvidencePackPath `
        -ReleaseVersion $ReleaseVersion `
        -RepoRoot $RepoRoot `
        -OutputPathOnly
}

$resolvedEvidencePackPath = (Resolve-Path $resolvedEvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath

$runLabelValue = Get-RecordedValue -Content $packContent -Label "Run Label"
$modeValue = Get-RecordedValue -Content $packContent -Label "Primary Mode" -DefaultValue "stable"
$releaseVersionValue = Get-RecordedValue -Content $packContent -Label "Release Version"
$loginTestReportPath = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $packContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $packContent -Label "Hardware Report"
$runbookPath = Get-RecordedValue -Content $packContent -Label "Runbook Path"

if ($runbookPath -eq "not-recorded-yet" -or -not (Test-Path $runbookPath)) {
    $runbookPath = & $runbookScript `
        -EvidencePackPath $resolvedEvidencePackPath `
        -ReleaseVersion $releaseVersionValue `
        -RepoRoot $RepoRoot `
        -OutputPathOnly
}

$null = & $syncControlCenterScript -RepoRoot $RepoRoot -OutputPathOnly

$currentEvidencePackSummaryPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-PACK.md"
$currentReleaseControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$safeRunLabel = Get-SafeFileSegment $runLabelValue
$sessionDir = Join-Path $RepoRoot ("status\evidence-packs\" + $dateStamp)
$sessionPath = Join-Path $sessionDir ("release-evidence-session-" + $safeRunLabel + ".md")

New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null

$content = @"
# Lumina-OS Release Evidence Session

- Created At: $(Get-Date -Format s)
- Session State: ready-to-collect-evidence
- Run Label: $runLabelValue
- Release Version: $releaseVersionValue
- Mode: $modeValue
- Evidence Pack: $resolvedEvidencePackPath
- Runbook Path: $runbookPath
- Login-Test Report: $loginTestReportPath
- Install Report: $installReportPath
- Hardware Report: $hardwareReportPath
- Current Evidence Pack Summary: $(if (Test-Path $currentEvidencePackSummaryPath) { $currentEvidencePackSummaryPath } else { "not-recorded-yet" })
- Current Release Control Center: $(if (Test-Path $currentReleaseControlCenterPath) { $currentReleaseControlCenterPath } else { "not-recorded-yet" })

## Practical Order
1. Update the login-test report at: $loginTestReportPath
2. Update the install report at: $installReportPath
3. Update the hardware report at: $hardwareReportPath
4. Sync the shared evidence pack with:
   .\scripts\sync-release-evidence-pack.ps1 -EvidencePackPath "$resolvedEvidencePackPath" -ReleaseVersion "$releaseVersionValue"
5. Review status/evidence-packs/CURRENT-EVIDENCE-PACK.md.
6. Run the evidence and readiness audits from the generated runbook:
   $runbookPath

## Goal
- keep the real validation session on one shared Run Label
- move from scaffolding into real login-test, install, and hardware evidence capture
"@

Set-Content -Path $sessionPath -Value $content -Encoding UTF8

$null = & $syncSessionStatusScript `
    -EvidenceSessionPath $sessionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $sessionPath
}
else {
    Write-Host "Started release evidence session:"
    Write-Host $sessionPath
}
