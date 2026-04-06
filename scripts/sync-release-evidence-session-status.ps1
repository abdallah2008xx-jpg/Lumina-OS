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
$sessionState = Get-RecordedValue -Content $sessionContent -Label "Session State"
$runLabel = Get-RecordedValue -Content $sessionContent -Label "Run Label"
$releaseVersion = Get-RecordedValue -Content $sessionContent -Label "Release Version"
$mode = Get-RecordedValue -Content $sessionContent -Label "Mode"
$evidencePackPath = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack"
$runbookPath = Get-RecordedValue -Content $sessionContent -Label "Runbook Path"
$loginTestReportPath = Get-RecordedValue -Content $sessionContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $sessionContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $sessionContent -Label "Hardware Report"
$currentEvidencePackSummaryPath = Get-RecordedValue -Content $sessionContent -Label "Current Evidence Pack Summary"
$currentReleaseControlCenterPath = Get-RecordedValue -Content $sessionContent -Label "Current Release Control Center"

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Run Label: $runLabel") | Out-Null
$summaryItems.Add("Mode: $mode") | Out-Null
$summaryItems.Add("Session State: $sessionState") | Out-Null

$nextItems = [System.Collections.Generic.List[string]]::new()
switch ($sessionState) {
    "ready-to-collect-evidence" {
        $nextItems.Add("Update the login-test, install, and hardware reports linked from this session.") | Out-Null
        $nextItems.Add("Rerun sync-release-evidence-pack.ps1 after each real evidence update.") | Out-Null
    }
    default {
        $nextItems.Add("Review the linked reports and refresh the evidence pack before RC gating.") | Out-Null
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
- Evidence Pack: $evidencePackPath
- Runbook Path: $runbookPath
- Current Evidence Pack Summary: $currentEvidencePackSummaryPath
- Current Release Control Center: $currentReleaseControlCenterPath

## Linked Reports
- Login-Test Report: $loginTestReportPath
- Install Report: $installReportPath
- Hardware Report: $hardwareReportPath

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
- Runbook Path: $(Get-ResolvedValue -Value $runbookPath)
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
