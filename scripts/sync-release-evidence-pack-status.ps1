param(
    [Parameter(Mandatory = $true)]
    [string]$EvidencePackPath,
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$controlCenterScript = Join-Path $PSScriptRoot "sync-release-control-center.ps1"
if (-not (Test-Path $controlCenterScript)) {
    throw "Missing helper script: $controlCenterScript"
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
    $safe = [regex]::Replace($safe, "[^a-z0-9\.\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

function Get-ResolvedValue {
    param(
        [string]$Value,
        [string]$DefaultValue = "not-recorded-yet"
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $DefaultValue
    }

    return $Value
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
}

if (-not (Test-Path $EvidencePackPath)) {
    throw "Evidence pack not found: $EvidencePackPath"
}

$resolvedEvidencePackPath = (Resolve-Path $EvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath

$createdAt = Get-RecordedValue -Content $packContent -Label "Created At"
$syncedAt = Get-RecordedValue -Content $packContent -Label "Synced At"
$runLabel = Get-RecordedValue -Content $packContent -Label "Run Label"
$mode = Get-RecordedValue -Content $packContent -Label "Primary Mode"
$vmType = Get-RecordedValue -Content $packContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $packContent -Label "Firmware"
$isoPath = Get-RecordedValue -Content $packContent -Label "ISO Path"
$releaseVersion = Get-RecordedValue -Content $packContent -Label "Release Version"
$deviceLabel = Get-RecordedValue -Content $packContent -Label "Device Label"
$bootSource = Get-RecordedValue -Content $packContent -Label "Boot Source"
$packState = Get-RecordedValue -Content $packContent -Label "Evidence Pack State"
$evidenceReadyCount = Get-RecordedValue -Content $packContent -Label "Evidence Ready Count"
$evidenceChecklistProgress = Get-RecordedValue -Content $packContent -Label "Evidence Checklist Progress"
$loginTestReportPath = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$loginTestStatus = Get-RecordedValue -Content $packContent -Label "Login-Test Status"
$loginTestRunLabel = Get-RecordedValue -Content $packContent -Label "Login-Test Run Label"
$loginTestTester = Get-RecordedValue -Content $packContent -Label "Login-Test Tester"
$loginTestProgressState = Get-RecordedValue -Content $packContent -Label "Login-Test Progress State"
$loginTestChecklistProgress = Get-RecordedValue -Content $packContent -Label "Login-Test Checklist Progress"
$installReportPath = Get-RecordedValue -Content $packContent -Label "Install Report"
$installStatus = Get-RecordedValue -Content $packContent -Label "Install Status"
$installRunLabel = Get-RecordedValue -Content $packContent -Label "Install Run Label"
$installTester = Get-RecordedValue -Content $packContent -Label "Install Tester"
$installProgressState = Get-RecordedValue -Content $packContent -Label "Install Progress State"
$installChecklistProgress = Get-RecordedValue -Content $packContent -Label "Install Checklist Progress"
$hardwareReportPath = Get-RecordedValue -Content $packContent -Label "Hardware Report"
$hardwareStatus = Get-RecordedValue -Content $packContent -Label "Hardware Status"
$hardwareRunLabel = Get-RecordedValue -Content $packContent -Label "Hardware Run Label"
$hardwareTester = Get-RecordedValue -Content $packContent -Label "Hardware Tester"
$hardwareProgressState = Get-RecordedValue -Content $packContent -Label "Hardware Progress State"
$hardwareChecklistProgress = Get-RecordedValue -Content $packContent -Label "Hardware Checklist Progress"
$runbookPath = Get-RecordedValue -Content $packContent -Label "Runbook Path"

$summaryItems = [System.Collections.Generic.List[string]]::new()
switch ($packState) {
    "ready-for-rc-gating" {
        $summaryItems.Add("This evidence pack is ready for RC gating.") | Out-Null
    }
    "run-label-mismatch" {
        $summaryItems.Add("One or more linked reports no longer match the shared run label.") | Out-Null
    }
    "missing-evidence" {
        $summaryItems.Add("At least one linked report is missing from disk.") | Out-Null
    }
    "incomplete" {
        $summaryItems.Add("The linked reports exist, but at least one status is not ready yet.") | Out-Null
    }
    default {
        $summaryItems.Add("Review the linked reports before using this evidence pack for RC gating.") | Out-Null
    }
}

$summaryItems.Add("Evidence Ready Count: $evidenceReadyCount") | Out-Null
$summaryItems.Add("Evidence Checklist Progress: $evidenceChecklistProgress") | Out-Null
$summaryItems.Add("Login-Test: $loginTestStatus | $loginTestChecklistProgress | tester: $loginTestTester") | Out-Null
$summaryItems.Add("Install: $installStatus | $installChecklistProgress | tester: $installTester") | Out-Null
$summaryItems.Add("Hardware: $hardwareStatus | $hardwareChecklistProgress | tester: $hardwareTester") | Out-Null

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\evidence-packs\" + $dateStamp)
$safeSuffix = if ($runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment (Split-Path -LeafBase $resolvedEvidencePackPath)
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("evidence-pack-status-" + $safeSuffix + ".md")
$currentStatusPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-PACK.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentStatusPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Evidence Pack Summary

- Updated At: $(Get-Date -Format s)
- Evidence Pack State: $packState
- Evidence Pack: $resolvedEvidencePackPath
- Run Label: $runLabel
- Primary Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- ISO Path: $isoPath
- Release Version: $releaseVersion
- Device Label: $deviceLabel
- Boot Source: $bootSource
- Created At: $createdAt
- Synced At: $syncedAt
- Evidence Ready Count: $evidenceReadyCount
- Evidence Checklist Progress: $evidenceChecklistProgress
- Runbook Path: $runbookPath

## Linked Evidence
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $loginTestStatus
- Login-Test Run Label: $loginTestRunLabel
- Login-Test Tester: $loginTestTester
- Login-Test Progress State: $loginTestProgressState
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Install Report: $installReportPath
- Install Status: $installStatus
- Install Run Label: $installRunLabel
- Install Tester: $installTester
- Install Progress State: $installProgressState
- Install Checklist Progress: $installChecklistProgress
- Hardware Report: $hardwareReportPath
- Hardware Status: $hardwareStatus
- Hardware Run Label: $hardwareRunLabel
- Hardware Tester: $hardwareTester
- Hardware Progress State: $hardwareProgressState
- Hardware Checklist Progress: $hardwareChecklistProgress

## Summary
$(Format-Items -Items $summaryItems)

## Recommendation
$(switch ($packState) {
    "ready-for-rc-gating" { "- move forward with `scripts/audit-release-evidence.ps1` or `scripts/prepare-release-candidate.ps1` using this pack." }
    "run-label-mismatch" { "- refresh or recreate the mismatched report so every evidence file carries the same run label." }
    "missing-evidence" { "- recreate the missing report or rebuild the evidence pack before RC gating." }
    "incomplete" { "- finish the missing validation steps, then rerun `scripts/sync-release-evidence-pack.ps1`." }
    default { "- inspect the pack manually, then rerun `scripts/sync-release-evidence-pack.ps1` after any change." }
})
"@

$currentContent = @"
# Lumina-OS Current Release Evidence Pack

- Updated At: $(Get-Date -Format s)
- Evidence Pack State: $packState
- Latest Summary: $summaryPath
- Evidence Pack: $resolvedEvidencePackPath
- Run Label: $runLabel
- Primary Mode: $mode
- Release Version: $releaseVersion
- Evidence Ready Count: $evidenceReadyCount
- Evidence Checklist Progress: $evidenceChecklistProgress
- Runbook Path: $(Get-ResolvedValue -Value $runbookPath)
- Login-Test Status: $loginTestStatus
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Install Status: $installStatus
- Install Checklist Progress: $installChecklistProgress
- Hardware Status: $hardwareStatus
- Hardware Checklist Progress: $hardwareChecklistProgress

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(switch ($packState) {
    "ready-for-rc-gating" { "- use this pack for release evidence audit or release-candidate prep." }
    "run-label-mismatch" { "- fix the mismatched report labels, then rerun `scripts/sync-release-evidence-pack.ps1`." }
    "missing-evidence" { "- recreate the missing report, then rerun `scripts/sync-release-evidence-pack.ps1`." }
    "incomplete" { "- complete the linked reports, then rerun `scripts/sync-release-evidence-pack.ps1`." }
    default { "- inspect the latest summary and decide whether another evidence-pack sync is needed." }
})
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentStatusPath -Value $currentContent -Encoding UTF8

$null = & $controlCenterScript `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Updated current release evidence pack:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $packState"
}
