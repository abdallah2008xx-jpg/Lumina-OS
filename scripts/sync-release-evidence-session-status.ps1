param(
    [Parameter(Mandatory = $true)]
    [string]$EvidenceSessionPath,
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

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
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

if (-not (Test-Path $EvidenceSessionPath)) {
    throw "Evidence session not found: $EvidenceSessionPath"
}

$resolvedEvidenceSessionPath = (Resolve-Path $EvidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$createdAt = Get-RecordedValue -Content $sessionContent -Label "Created At"
$syncedAt = Get-RecordedValue -Content $sessionContent -Label "Synced At"
$sessionState = Get-RecordedValue -Content $sessionContent -Label "Session State"
$runLabel = Get-RecordedValue -Content $sessionContent -Label "Run Label"
$releaseVersion = Get-RecordedValue -Content $sessionContent -Label "Release Version"
$mode = Get-RecordedValue -Content $sessionContent -Label "Mode"
$evidencePackPath = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack"
$evidencePackState = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack State"
$evidenceReadyCount = Get-RecordedValue -Content $sessionContent -Label "Evidence Ready Count"
$evidenceChecklistProgress = Get-RecordedValue -Content $sessionContent -Label "Evidence Checklist Progress"
$runbookPath = Get-RecordedValue -Content $sessionContent -Label "Runbook Path"
$loginTestReportPath = Get-RecordedValue -Content $sessionContent -Label "Login-Test Report"
$loginTestStatus = Get-RecordedValue -Content $sessionContent -Label "Login-Test Status"
$loginTestTester = Get-RecordedValue -Content $sessionContent -Label "Login-Test Tester"
$loginTestChecklistProgress = Get-RecordedValue -Content $sessionContent -Label "Login-Test Checklist Progress"
$installReportPath = Get-RecordedValue -Content $sessionContent -Label "Install Report"
$installStatus = Get-RecordedValue -Content $sessionContent -Label "Install Status"
$installTester = Get-RecordedValue -Content $sessionContent -Label "Install Tester"
$installChecklistProgress = Get-RecordedValue -Content $sessionContent -Label "Install Checklist Progress"
$hardwareReportPath = Get-RecordedValue -Content $sessionContent -Label "Hardware Report"
$hardwareStatus = Get-RecordedValue -Content $sessionContent -Label "Hardware Status"
$hardwareTester = Get-RecordedValue -Content $sessionContent -Label "Hardware Tester"
$hardwareChecklistProgress = Get-RecordedValue -Content $sessionContent -Label "Hardware Checklist Progress"
$nextEvidenceTarget = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Target"
$nextEvidenceReportPath = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Report"
$nextEvidenceTester = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Tester"
$nextEvidenceProgress = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Progress"
$nextActionPath = Get-RecordedValue -Content $sessionContent -Label "Next Action Path"
$nextActionLauncherPath = Get-RecordedValue -Content $sessionContent -Label "Next Action Launcher"
$actionPackPath = Get-RecordedValue -Content $sessionContent -Label "Action Pack Path"
$currentEvidencePackSummaryPath = Get-RecordedValue -Content $sessionContent -Label "Current Evidence Pack Summary"
$currentReleaseControlCenterPath = Get-RecordedValue -Content $sessionContent -Label "Current Release Control Center"

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Run Label: $runLabel") | Out-Null
$summaryItems.Add("Mode: $mode") | Out-Null
$summaryItems.Add("Session State: $sessionState") | Out-Null
$summaryItems.Add("Evidence Pack State: $evidencePackState") | Out-Null
$summaryItems.Add("Evidence Ready Count: $evidenceReadyCount") | Out-Null
$summaryItems.Add("Evidence Checklist Progress: $evidenceChecklistProgress") | Out-Null
$summaryItems.Add("Next Evidence Target: $nextEvidenceTarget") | Out-Null
$summaryItems.Add("Next Evidence Progress: $nextEvidenceProgress") | Out-Null
$summaryItems.Add("Next Action Path: $nextActionPath") | Out-Null
$summaryItems.Add("Synced At: $syncedAt") | Out-Null

$nextItems = [System.Collections.Generic.List[string]]::new()
switch ($sessionState) {
    "ready-to-collect-evidence" {
        $nextItems.Add("Start with the next missing evidence target from this session.") | Out-Null
        $nextItems.Add("Next Evidence Target: $nextEvidenceTarget") | Out-Null
        $nextItems.Add("Next Evidence Report: $nextEvidenceReportPath") | Out-Null
        $nextItems.Add("Next Evidence Progress: $nextEvidenceProgress") | Out-Null
        $nextItems.Add("Next Evidence Tester: $nextEvidenceTester") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
        $nextItems.Add("Next Action Launcher: $nextActionLauncherPath") | Out-Null
        $nextItems.Add("Rerun sync-release-evidence-session.ps1 after each real evidence update.") | Out-Null
    }
    "evidence-in-progress" {
        $nextItems.Add("Continue with the next missing evidence target from this session.") | Out-Null
        $nextItems.Add("Next Evidence Target: $nextEvidenceTarget") | Out-Null
        $nextItems.Add("Next Evidence Report: $nextEvidenceReportPath") | Out-Null
        $nextItems.Add("Next Evidence Progress: $nextEvidenceProgress") | Out-Null
        $nextItems.Add("Next Evidence Tester: $nextEvidenceTester") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
        $nextItems.Add("Next Action Launcher: $nextActionLauncherPath") | Out-Null
        $nextItems.Add("Rerun sync-release-evidence-session.ps1 after each report update.") | Out-Null
    }
    "ready-for-rc-gating" {
        $nextItems.Add("Use the linked runbook to start evidence audit and release-candidate prep.") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
        $nextItems.Add("Next Action Launcher: $nextActionLauncherPath") | Out-Null
    }
    default {
        $nextItems.Add("Review the linked reports and refresh the evidence pack before RC gating.") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\evidence-packs\" + $dateStamp)
$safeSuffix = if ($runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment (Split-Path -LeafBase $resolvedEvidenceSessionPath)
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("evidence-session-status-" + $safeSuffix + ".md")
$currentStatusPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentStatusPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Evidence Session Summary

- Updated At: $(Get-Date -Format s)
- Session State: $sessionState
- Evidence Session: $resolvedEvidenceSessionPath
- Run Label: $runLabel
- Release Version: $releaseVersion
- Mode: $mode
- Created At: $createdAt
- Synced At: $syncedAt
- Evidence Pack: $evidencePackPath
- Evidence Pack State: $evidencePackState
- Evidence Ready Count: $evidenceReadyCount
- Evidence Checklist Progress: $evidenceChecklistProgress
- Runbook Path: $runbookPath
- Action Pack Path: $actionPackPath
- Next Evidence Target: $nextEvidenceTarget
- Next Evidence Report: $nextEvidenceReportPath
- Next Evidence Tester: $nextEvidenceTester
- Next Evidence Progress: $nextEvidenceProgress
- Next Action Path: $nextActionPath
- Next Action Launcher: $nextActionLauncherPath
- Current Evidence Pack Summary: $currentEvidencePackSummaryPath
- Current Release Control Center: $currentReleaseControlCenterPath

## Linked Reports
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $loginTestStatus
- Login-Test Tester: $loginTestTester
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Install Report: $installReportPath
- Install Status: $installStatus
- Install Tester: $installTester
- Install Checklist Progress: $installChecklistProgress
- Hardware Report: $hardwareReportPath
- Hardware Status: $hardwareStatus
- Hardware Tester: $hardwareTester
- Hardware Checklist Progress: $hardwareChecklistProgress

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

$currentContent = @"
# Lumina-OS Current Release Evidence Session

- Updated At: $(Get-Date -Format s)
- Session State: $sessionState
- Latest Summary: $summaryPath
- Evidence Session: $resolvedEvidenceSessionPath
- Run Label: $runLabel
- Release Version: $releaseVersion
- Mode: $mode
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Evidence Pack State: $(Get-ResolvedValue -Value $evidencePackState)
- Evidence Ready Count: $(Get-ResolvedValue -Value $evidenceReadyCount)
- Evidence Checklist Progress: $(Get-ResolvedValue -Value $evidenceChecklistProgress)
- Runbook Path: $(Get-ResolvedValue -Value $runbookPath)
- Action Pack Path: $(Get-ResolvedValue -Value $actionPackPath)
- Next Evidence Target: $(Get-ResolvedValue -Value $nextEvidenceTarget)
- Next Evidence Report: $(Get-ResolvedValue -Value $nextEvidenceReportPath)
- Next Evidence Tester: $(Get-ResolvedValue -Value $nextEvidenceTester)
- Next Evidence Progress: $(Get-ResolvedValue -Value $nextEvidenceProgress)
- Next Action Path: $(Get-ResolvedValue -Value $nextActionPath)
- Next Action Launcher: $(Get-ResolvedValue -Value $nextActionLauncherPath)
- Synced At: $(Get-ResolvedValue -Value $syncedAt)
- Current Evidence Pack Summary: $(Get-ResolvedValue -Value $currentEvidencePackSummaryPath)
- Current Release Control Center: $(Get-ResolvedValue -Value $currentReleaseControlCenterPath)

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
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
    Write-Host "Updated current release evidence session:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $sessionState"
}
