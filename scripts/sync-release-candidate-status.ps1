param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseManifestPath,
    [string]$ValidationReportPath = "",
    [string]$PublishRecordPath = "",
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

function Get-ResolvedPathOrDefault {
    param(
        [string]$Value,
        [string]$DefaultValue
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

if (-not (Test-Path $ReleaseManifestPath)) {
    throw "Release manifest not found: $ReleaseManifestPath"
}

$resolvedManifestPath = (Resolve-Path $ReleaseManifestPath).Path
$releaseDir = Split-Path -Parent $resolvedManifestPath
$resolvedValidationReportPath = if ([string]::IsNullOrWhiteSpace($ValidationReportPath)) {
    Join-Path $releaseDir "release-validation.md"
}
else {
    $ValidationReportPath
}
$resolvedPublishRecordPath = if ([string]::IsNullOrWhiteSpace($PublishRecordPath)) {
    Join-Path $releaseDir "github-release-publish.md"
}
else {
    $PublishRecordPath
}

$manifestContent = Get-Content -Raw $resolvedManifestPath
$validationContent = if (Test-Path $resolvedValidationReportPath) { Get-Content -Raw $resolvedValidationReportPath } else { "" }
$publishContent = if (Test-Path $resolvedPublishRecordPath) { Get-Content -Raw $resolvedPublishRecordPath } else { "" }

$versionLabel = Get-MetadataValue -Content $manifestContent -Label "Version"
$modeLabel = Get-MetadataValue -Content $manifestContent -Label "Mode"
$runLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$isoPathLabel = Get-MetadataValue -Content $manifestContent -Label "ISO Path"
$buildManifestLabel = Get-MetadataValue -Content $manifestContent -Label "Build Manifest"
$vmReportLabel = Get-MetadataValue -Content $manifestContent -Label "VM Report"
$installReportLabel = Get-MetadataValue -Content $manifestContent -Label "Install Report"
$hardwareReportLabel = Get-MetadataValue -Content $manifestContent -Label "Hardware Report"
$sessionSummaryLabel = Get-MetadataValue -Content $manifestContent -Label "Session Summary"
$sessionAuditLabel = Get-MetadataValue -Content $manifestContent -Label "Session Audit"
$cycleChainAuditLabel = Get-MetadataValue -Content $manifestContent -Label "Cycle Chain Audit"
$readinessLabel = Get-MetadataValue -Content $manifestContent -Label "Readiness"
$validationMatrixLabel = Get-MetadataValue -Content $manifestContent -Label "Validation Matrix"

$validationResult = Get-MetadataValue -Content $validationContent -Label "Result"
$installReportState = Get-MetadataValue -Content $validationContent -Label "Install Report Status"
$hardwareReportState = Get-MetadataValue -Content $validationContent -Label "Hardware Report Status"
$readinessState = Get-MetadataValue -Content $validationContent -Label "Readiness State"
$validationMatrixState = Get-MetadataValue -Content $validationContent -Label "Validation Matrix State"
$blockerState = Get-MetadataValue -Content $validationContent -Label "Blocker State"
$publishUrl = Get-MetadataValue -Content $publishContent -Label "Release URL"
$publishId = Get-MetadataValue -Content $publishContent -Label "Release ID"

$candidateState = switch ($validationResult) {
    "passed" {
        if (Test-Path $resolvedPublishRecordPath) {
            "published"
        }
        else {
            "ready-to-publish"
        }
        break
    }
    "failed" { "blocked"; break }
    default { "review-required" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
switch ($candidateState) {
    "ready-to-publish" {
        $summaryItems.Add("Release package and validation report are in place for the selected run.") | Out-Null
    }
    "published" {
        $summaryItems.Add("This release candidate already has a GitHub publish record.") | Out-Null
    }
    "blocked" {
        $summaryItems.Add("The release candidate is blocked because release validation did not pass.") | Out-Null
    }
    default {
        $summaryItems.Add("The release candidate needs manual review before publish.") | Out-Null
    }
}

if (-not [string]::IsNullOrWhiteSpace($readinessState)) {
    $summaryItems.Add("Readiness State: $readinessState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($validationMatrixState)) {
    $summaryItems.Add("Validation Matrix State: $validationMatrixState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($blockerState)) {
    $summaryItems.Add("Blocker State: $blockerState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($installReportState)) {
    $summaryItems.Add("Install Report Status: $installReportState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($hardwareReportState)) {
    $summaryItems.Add("Hardware Report Status: $hardwareReportState") | Out-Null
}

if ((Test-Path $resolvedPublishRecordPath) -and -not [string]::IsNullOrWhiteSpace($publishUrl)) {
    $summaryItems.Add("Published Release URL: $publishUrl") | Out-Null
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$candidateRoot = Join-Path $RepoRoot ("status\release-candidates\" + $dateStamp)
$safeSuffix = if ([string]::IsNullOrWhiteSpace($runLabel) -or $runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment $versionLabel
}
else {
    Get-SafeFileSegment $runLabel
}
$candidateSummaryPath = Join-Path $candidateRoot ("release-candidate-" + $safeSuffix + ".md")
$currentCandidatePath = Join-Path $RepoRoot "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md"

New-Item -ItemType Directory -Force -Path $candidateRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentCandidatePath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Candidate Summary

- Prepared At: $(Get-Date -Format s)
- Candidate State: $candidateState
- Validation Result: $(if ([string]::IsNullOrWhiteSpace($validationResult)) { "not-recorded-yet" } else { $validationResult })
- Version: $(Get-ResolvedPathOrDefault -Value $versionLabel -DefaultValue "not-recorded-yet")
- Mode: $(Get-ResolvedPathOrDefault -Value $modeLabel -DefaultValue "not-recorded-yet")
- Run Label: $(Get-ResolvedPathOrDefault -Value $runLabel -DefaultValue "not-recorded-yet")
- Release Manifest: $resolvedManifestPath
- Validation Report: $(if (Test-Path $resolvedValidationReportPath) { $resolvedValidationReportPath } else { "not-recorded-yet" })
- Publish Record: $(if (Test-Path $resolvedPublishRecordPath) { $resolvedPublishRecordPath } else { "not-recorded-yet" })

## Evidence Links
- ISO Path: $(Get-ResolvedPathOrDefault -Value $isoPathLabel -DefaultValue "not-recorded-yet")
- Build Manifest: $(Get-ResolvedPathOrDefault -Value $buildManifestLabel -DefaultValue "not-recorded-yet")
- VM Report: $(Get-ResolvedPathOrDefault -Value $vmReportLabel -DefaultValue "not-recorded-yet")
- Install Report: $(Get-ResolvedPathOrDefault -Value $installReportLabel -DefaultValue "not-recorded-yet")
- Hardware Report: $(Get-ResolvedPathOrDefault -Value $hardwareReportLabel -DefaultValue "not-recorded-yet")
- Session Summary: $(Get-ResolvedPathOrDefault -Value $sessionSummaryLabel -DefaultValue "not-recorded-yet")
- Session Audit: $(Get-ResolvedPathOrDefault -Value $sessionAuditLabel -DefaultValue "not-recorded-yet")
- Cycle Chain Audit: $(Get-ResolvedPathOrDefault -Value $cycleChainAuditLabel -DefaultValue "not-recorded-yet")
- Readiness: $(Get-ResolvedPathOrDefault -Value $readinessLabel -DefaultValue "not-recorded-yet")
- Validation Matrix: $(Get-ResolvedPathOrDefault -Value $validationMatrixLabel -DefaultValue "not-recorded-yet")

## Summary
$(Format-Items -Items $summaryItems)

## Publish Details
- Release URL: $(Get-ResolvedPathOrDefault -Value $publishUrl -DefaultValue "not-recorded-yet")
- Release ID: $(Get-ResolvedPathOrDefault -Value $publishId -DefaultValue "not-recorded-yet")

## Recommendation
$(switch ($candidateState) {
    "ready-to-publish" { "- this candidate is ready for `scripts/publish-github-release.ps1` after one last wording review of release notes." }
    "published" { "- this candidate is already published; keep this summary as the release trace record." }
    "blocked" { "- fix the validation failures in `release-validation.md` before trying to publish." }
    default { "- inspect the generated manifest, validation report, and evidence files manually before deciding to publish." }
})
"@

$currentContent = @"
# Lumina-OS Current Release Candidate

- Updated At: $(Get-Date -Format s)
- Candidate State: $candidateState
- Latest Summary: $candidateSummaryPath
- Version: $(Get-ResolvedPathOrDefault -Value $versionLabel -DefaultValue "not-recorded-yet")
- Mode: $(Get-ResolvedPathOrDefault -Value $modeLabel -DefaultValue "not-recorded-yet")
- Run Label: $(Get-ResolvedPathOrDefault -Value $runLabel -DefaultValue "not-recorded-yet")
- Release Manifest: $resolvedManifestPath
- Validation Report: $(if (Test-Path $resolvedValidationReportPath) { $resolvedValidationReportPath } else { "not-recorded-yet" })
- Publish Record: $(if (Test-Path $resolvedPublishRecordPath) { $resolvedPublishRecordPath } else { "not-recorded-yet" })

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(switch ($candidateState) {
    "ready-to-publish" { "- publish this candidate with `scripts/publish-github-release.ps1` when the release notes wording is final." }
    "published" { "- use this file as the current release trace reference until the next candidate is prepared." }
    "blocked" { "- resolve the validation errors and rerun `scripts/prepare-release-candidate.ps1` or `scripts/sync-release-candidate-status.ps1`." }
    default { "- inspect the latest candidate manually and decide whether another sync pass is needed." }
})
"@

Set-Content -Path $candidateSummaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentCandidatePath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $candidateSummaryPath
}
else {
    Write-Host "Updated Lumina-OS release candidate status:"
    Write-Host "Summary: $candidateSummaryPath"
    Write-Host "State:   $candidateState"
}
