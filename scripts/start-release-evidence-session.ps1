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
$syncSessionScript = Join-Path $PSScriptRoot "sync-release-evidence-session.ps1"

foreach ($requiredScript in @($newPackScript, $runbookScript, $syncPackScript, $syncSessionScript)) {
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

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$safeRunLabel = Get-SafeFileSegment $runLabelValue
$sessionDir = Join-Path $RepoRoot ("status\evidence-packs\" + $dateStamp)
$sessionPath = Join-Path $sessionDir ("release-evidence-session-" + $safeRunLabel + ".md")

New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null

$content = @"
# Lumina-OS Release Evidence Session

- Created At: $(Get-Date -Format s)
- Synced At: not-recorded-yet
- Session State: ready-to-collect-evidence
- Run Label: $runLabelValue
- Release Version: $releaseVersionValue
- Mode: $modeValue
- Evidence Pack: $resolvedEvidencePackPath
- Evidence Pack State: not-recorded-yet
- Runbook Path: $runbookPath
- Login-Test Report: $loginTestReportPath
- Login-Test Status: not-recorded-yet
- Login-Test Run Label: not-recorded-yet
- Install Report: $installReportPath
- Install Status: not-recorded-yet
- Install Run Label: not-recorded-yet
- Hardware Report: $hardwareReportPath
- Hardware Status: not-recorded-yet
- Hardware Run Label: not-recorded-yet
- Current Evidence Pack Summary: not-recorded-yet
- Current Release Control Center: not-recorded-yet

## Practical Order
1. Update the login-test report at: $loginTestReportPath
2. Update the install report at: $installReportPath
3. Update the hardware report at: $hardwareReportPath
4. Refresh this evidence session after report updates with:
   .\scripts\sync-release-evidence-session.ps1 -EvidenceSessionPath "$sessionPath" -ReleaseVersion "$releaseVersionValue"
5. Review status/evidence-packs/CURRENT-EVIDENCE-SESSION.md and status/evidence-packs/CURRENT-EVIDENCE-PACK.md.
6. Run the evidence and readiness audits from the generated runbook:
   $runbookPath

## Goal
- keep the real validation session on one shared Run Label
- move from scaffolding into real login-test, install, and hardware evidence capture
"@

Set-Content -Path $sessionPath -Value $content -Encoding UTF8

$null = & $syncSessionScript `
    -EvidenceSessionPath $sessionPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $sessionPath
}
else {
    Write-Host "Started release evidence session:"
    Write-Host $sessionPath
}
