param(
    [Parameter(Mandatory = $true)]
    [string]$EvidencePackPath,
    [string]$ReleaseVersion = "",
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

function Get-ReportAudit {
    param(
        [string]$Path,
        [string]$Target
    )

    $rawJson = (& $reportAuditScript `
        -ReportPath $Path `
        -Target $Target `
        -AsJson) | Out-String

    $trimmedJson = $rawJson.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedJson)) {
        throw "Failed to audit release evidence target: $Path"
    }

    return ($trimmedJson | ConvertFrom-Json)
}

if (-not (Test-Path $EvidencePackPath)) {
    throw "Evidence pack path not found: $EvidencePackPath"
}

$runbookScript = Join-Path $PSScriptRoot "new-release-evidence-runbook.ps1"
if (-not (Test-Path $runbookScript)) {
    throw "Missing helper script: $runbookScript"
}

$reportAuditScript = Join-Path $PSScriptRoot "audit-release-evidence-target.ps1"
if (-not (Test-Path $reportAuditScript)) {
    throw "Missing helper script: $reportAuditScript"
}

$statusScript = Join-Path $PSScriptRoot "sync-release-evidence-pack-status.ps1"
if (-not (Test-Path $statusScript)) {
    throw "Missing helper script: $statusScript"
}

$resolvedEvidencePackPath = (Resolve-Path $EvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath

$createdAt = Get-RecordedValue -Content $packContent -Label "Created At"
$runLabel = Get-RecordedValue -Content $packContent -Label "Run Label"
$mode = Get-RecordedValue -Content $packContent -Label "Primary Mode" -DefaultValue "stable"
$vmType = Get-RecordedValue -Content $packContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $packContent -Label "Firmware"
$isoPath = Get-RecordedValue -Content $packContent -Label "ISO Path"
$storedReleaseVersion = Get-RecordedValue -Content $packContent -Label "Release Version"
$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) { $storedReleaseVersion } else { $ReleaseVersion.Trim() }
$deviceLabel = Get-RecordedValue -Content $packContent -Label "Device Label"
$bootSource = Get-RecordedValue -Content $packContent -Label "Boot Source"
$loginTestReportPath = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $packContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $packContent -Label "Hardware Report"
$runbookPath = Get-RecordedValue -Content $packContent -Label "Runbook Path"

$loginTestSnapshot = Get-ReportAudit -Path $loginTestReportPath -Target "login-test"
$installSnapshot = Get-ReportAudit -Path $installReportPath -Target "install"
$hardwareSnapshot = Get-ReportAudit -Path $hardwareReportPath -Target "hardware"

$allExist = $loginTestSnapshot.Exists -and $installSnapshot.Exists -and $hardwareSnapshot.Exists
$allPass = $loginTestSnapshot.ReadyForGate -and $installSnapshot.ReadyForGate -and $hardwareSnapshot.ReadyForGate
$runLabelMatch = (
    $loginTestSnapshot.RunLabel -eq $runLabel -and
    $installSnapshot.RunLabel -eq $runLabel -and
    $hardwareSnapshot.RunLabel -eq $runLabel
)

$readyCount = @(
    [bool]$loginTestSnapshot.ReadyForGate,
    [bool]$installSnapshot.ReadyForGate,
    [bool]$hardwareSnapshot.ReadyForGate
) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
$readyCountSummary = "$readyCount/3"
$totalChecklistItems = [int]$loginTestSnapshot.TotalChecklistItems + [int]$installSnapshot.TotalChecklistItems + [int]$hardwareSnapshot.TotalChecklistItems
$checkedChecklistItems = [int]$loginTestSnapshot.CheckedChecklistItems + [int]$installSnapshot.CheckedChecklistItems + [int]$hardwareSnapshot.CheckedChecklistItems
$checklistProgressSummary = if ($totalChecklistItems -gt 0) {
    $progressPercent = [int][Math]::Round(($checkedChecklistItems / $totalChecklistItems) * 100)
    "$checkedChecklistItems/$totalChecklistItems complete ($progressPercent%)"
}
else {
    "0/0 complete (0%)"
}

$evidencePackState = if (-not $allExist) {
    "missing-evidence"
}
elseif (-not $runLabelMatch) {
    "run-label-mismatch"
}
elseif (-not $allPass) {
    "incomplete"
}
else {
    "ready-for-rc-gating"
}

$content = @"
# Lumina-OS Release Evidence Pack

- Created At: $createdAt
- Synced At: $(Get-Date -Format s)
- Run Label: $runLabel
- Primary Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- ISO Path: $isoPath
- Release Version: $releaseVersionValue
- Device Label: $deviceLabel
- Boot Source: $bootSource
- Evidence Pack State: $evidencePackState
- Evidence Ready Count: $readyCountSummary
- Evidence Checklist Progress: $checklistProgressSummary
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $($loginTestSnapshot.Status)
- Login-Test Run Label: $($loginTestSnapshot.RunLabel)
- Login-Test Tester: $($loginTestSnapshot.Tester)
- Login-Test Progress State: $($loginTestSnapshot.ProgressState)
- Login-Test Checklist Progress: $($loginTestSnapshot.ChecklistSummary)
- Login-Test Open Items: $($loginTestSnapshot.OpenChecklistItems)
- Login-Test Findings State: $($loginTestSnapshot.FindingsState)
- Login-Test Blockers State: $($loginTestSnapshot.BlockersState)
- Install Report: $installReportPath
- Install Status: $($installSnapshot.Status)
- Install Run Label: $($installSnapshot.RunLabel)
- Install Tester: $($installSnapshot.Tester)
- Install Progress State: $($installSnapshot.ProgressState)
- Install Checklist Progress: $($installSnapshot.ChecklistSummary)
- Install Open Items: $($installSnapshot.OpenChecklistItems)
- Install Findings State: $($installSnapshot.FindingsState)
- Install Blockers State: $($installSnapshot.BlockersState)
- Hardware Report: $hardwareReportPath
- Hardware Status: $($hardwareSnapshot.Status)
- Hardware Run Label: $($hardwareSnapshot.RunLabel)
- Hardware Tester: $($hardwareSnapshot.Tester)
- Hardware Progress State: $($hardwareSnapshot.ProgressState)
- Hardware Checklist Progress: $($hardwareSnapshot.ChecklistSummary)
- Hardware Open Items: $($hardwareSnapshot.OpenChecklistItems)
- Hardware Findings State: $($hardwareSnapshot.FindingsState)
- Hardware Blockers State: $($hardwareSnapshot.BlockersState)
- Runbook Path: $runbookPath

## Purpose
- keep `login-test`, `install`, and `hardware` evidence on the same `Run Label`
- reduce release-prep drift before the final RC gate
- keep real report progress visible instead of relying on status labels alone

## Next Step
- rerun `new-release-evidence-runbook.ps1` or use this pack directly in release evidence audit and RC prep
- if `Evidence Pack State` is not `ready-for-rc-gating`, fix the missing or mismatched evidence before strict release gating
"@

Set-Content -Path $resolvedEvidencePackPath -Value $content -Encoding UTF8

$runbookPath = & $runbookScript `
    -EvidencePackPath $resolvedEvidencePackPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$null = & $statusScript `
    -EvidencePackPath $resolvedEvidencePackPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $resolvedEvidencePackPath
}
else {
    Write-Host "Synced release evidence pack:"
    Write-Host $resolvedEvidencePackPath
}
