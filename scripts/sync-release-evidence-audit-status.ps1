param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseEvidenceAuditPath,
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

if (-not (Test-Path $ReleaseEvidenceAuditPath)) {
    throw "Release evidence audit not found: $ReleaseEvidenceAuditPath"
}

$resolvedAuditPath = (Resolve-Path $ReleaseEvidenceAuditPath).Path
$auditContent = Get-Content -Raw $resolvedAuditPath

$auditedAt = Get-MetadataValue -Content $auditContent -Label "Audited At"
$version = Get-MetadataValue -Content $auditContent -Label "Version"
$mode = Get-MetadataValue -Content $auditContent -Label "Mode"
$runLabel = Get-MetadataValue -Content $auditContent -Label "Run Label"
$releaseManifestPath = Get-MetadataValue -Content $auditContent -Label "Release Manifest"
$softValidationReport = Get-MetadataValue -Content $auditContent -Label "Soft Validation Report"
$softGateState = Get-MetadataValue -Content $auditContent -Label "Soft Gate State"
$softGateResult = Get-MetadataValue -Content $auditContent -Label "Soft Gate Result"
$strictValidationReport = Get-MetadataValue -Content $auditContent -Label "Strict Validation Report"
$strictGateState = Get-MetadataValue -Content $auditContent -Label "Strict Gate State"
$strictGateResult = Get-MetadataValue -Content $auditContent -Label "Strict Gate Result"
$isoPath = Get-MetadataValue -Content $auditContent -Label "ISO Path"
$evidencePackPath = Get-MetadataValue -Content $auditContent -Label "Evidence Pack"
$loginTestReport = Get-MetadataValue -Content $auditContent -Label "Login-Test Report"
$installReport = Get-MetadataValue -Content $auditContent -Label "Install Report"
$hardwareReport = Get-MetadataValue -Content $auditContent -Label "Hardware Report"

$auditState = switch ($true) {
    { $softGateState -eq "passed" -and $strictGateState -eq "passed" } { "soft-and-strict-passed"; break }
    { $softGateState -eq "passed" } { "soft-passed-strict-pending"; break }
    default { "not-ready" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
switch ($auditState) {
    "soft-and-strict-passed" {
        $summaryItems.Add("Soft and strict evidence gates both pass.") | Out-Null
    }
    "soft-passed-strict-pending" {
        $summaryItems.Add("Soft evidence is acceptable, but strict evidence still needs exact coverage.") | Out-Null
    }
    default {
        $summaryItems.Add("Release evidence is not ready yet.") | Out-Null
    }
}

if (-not [string]::IsNullOrWhiteSpace($softGateState)) {
    $summaryItems.Add("Soft Gate State: $softGateState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($strictGateState)) {
    $summaryItems.Add("Strict Gate State: $strictGateState") | Out-Null
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$safeSuffix = if ([string]::IsNullOrWhiteSpace($runLabel) -or $runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment $version
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("release-evidence-status-" + $safeSuffix + ".md")
$currentPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-EVIDENCE.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Evidence Summary

- Updated At: $(Get-Date -Format s)
- Evidence Audit State: $auditState
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Release Evidence Audit: $resolvedAuditPath
- Release Manifest: $(Get-ResolvedValue -Value $releaseManifestPath)
- Soft Validation Report: $(Get-ResolvedValue -Value $softValidationReport)
- Soft Gate State: $(Get-ResolvedValue -Value $softGateState)
- Soft Gate Result: $(Get-ResolvedValue -Value $softGateResult)
- Strict Validation Report: $(Get-ResolvedValue -Value $strictValidationReport)
- Strict Gate State: $(Get-ResolvedValue -Value $strictGateState)
- Strict Gate Result: $(Get-ResolvedValue -Value $strictGateResult)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- ISO Path: $(Get-ResolvedValue -Value $isoPath)
- Login-Test Report: $(Get-ResolvedValue -Value $loginTestReport)
- Install Report: $(Get-ResolvedValue -Value $installReport)
- Hardware Report: $(Get-ResolvedValue -Value $hardwareReport)
- Audited At: $(Get-ResolvedValue -Value $auditedAt)

## Summary
$(Format-Items -Items $summaryItems)

## Recommendation
$(switch ($auditState) {
    "soft-and-strict-passed" { "- proceed with release-readiness audit or strict release-candidate prep from this evidence chain." }
    "soft-passed-strict-pending" { "- tighten exact install/hardware evidence before relying on strict release gating." }
    default { "- fix the failing evidence gates, then rerun `scripts/audit-release-evidence.ps1`." }
})
"@

$currentContent = @"
# Lumina-OS Current Release Evidence

- Updated At: $(Get-Date -Format s)
- Evidence Audit State: $auditState
- Latest Summary: $summaryPath
- Release Evidence Audit: $resolvedAuditPath
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Soft Gate State: $(Get-ResolvedValue -Value $softGateState)
- Strict Gate State: $(Get-ResolvedValue -Value $strictGateState)

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(switch ($auditState) {
    "soft-and-strict-passed" { "- move forward to release-readiness audit or strict RC prep." }
    "soft-passed-strict-pending" { "- improve exact evidence coverage, then rerun `scripts/audit-release-evidence.ps1`." }
    default { "- close the missing evidence gates, then rerun `scripts/audit-release-evidence.ps1`." }
})
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Updated current release evidence:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $auditState"
}
