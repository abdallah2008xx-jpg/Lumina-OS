param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseReadinessAuditPath,
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

if (-not (Test-Path $ReleaseReadinessAuditPath)) {
    throw "Release readiness audit not found: $ReleaseReadinessAuditPath"
}

$resolvedAuditPath = (Resolve-Path $ReleaseReadinessAuditPath).Path
$auditContent = Get-Content -Raw $resolvedAuditPath

$auditedAt = Get-MetadataValue -Content $auditContent -Label "Audited At"
$version = Get-MetadataValue -Content $auditContent -Label "Version"
$mode = Get-MetadataValue -Content $auditContent -Label "Mode"
$runLabel = Get-MetadataValue -Content $auditContent -Label "Run Label"
$overallReadiness = Get-MetadataValue -Content $auditContent -Label "Overall Readiness"
$readinessState = Get-MetadataValue -Content $auditContent -Label "Readiness State"
$validationState = Get-MetadataValue -Content $auditContent -Label "Validation Matrix State"
$candidateState = Get-MetadataValue -Content $auditContent -Label "Candidate State"
$candidateVersion = Get-MetadataValue -Content $auditContent -Label "Candidate Version"
$releaseEvidenceAuditPath = Get-MetadataValue -Content $auditContent -Label "Release Evidence Audit"
$evidencePackPath = Get-MetadataValue -Content $auditContent -Label "Evidence Pack"
$softGateState = Get-MetadataValue -Content $auditContent -Label "Soft Gate State"
$softGateResult = Get-MetadataValue -Content $auditContent -Label "Soft Gate Result"
$strictGateState = Get-MetadataValue -Content $auditContent -Label "Strict Gate State"
$strictGateResult = Get-MetadataValue -Content $auditContent -Label "Strict Gate Result"
$releaseCandidatePath = Get-MetadataValue -Content $auditContent -Label "Release Candidate Path"
$releaseManifestPath = Get-MetadataValue -Content $auditContent -Label "Release Manifest"

$summaryItems = [System.Collections.Generic.List[string]]::new()
switch ($overallReadiness) {
    "published" {
        $summaryItems.Add("The tracked release candidate is already published.") | Out-Null
    }
    "ready-to-publish" {
        $summaryItems.Add("The tracked release candidate is ready to publish.") | Out-Null
    }
    "ready-for-strict-release-candidate" {
        $summaryItems.Add("Strict evidence is aligned and ready for RC preparation.") | Out-Null
    }
    "ready-for-soft-release-candidate" {
        $summaryItems.Add("Soft evidence is aligned, but strict evidence still needs tightening.") | Out-Null
    }
    default {
        $summaryItems.Add("Release readiness is not complete yet.") | Out-Null
    }
}

if (-not [string]::IsNullOrWhiteSpace($softGateState)) {
    $summaryItems.Add("Soft Gate State: $softGateState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($strictGateState)) {
    $summaryItems.Add("Strict Gate State: $strictGateState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($candidateState)) {
    $summaryItems.Add("Candidate State: $candidateState") | Out-Null
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$safeSuffix = if ([string]::IsNullOrWhiteSpace($runLabel) -or $runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment $version
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("release-readiness-status-" + $safeSuffix + ".md")
$currentPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-READINESS.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Readiness Summary

- Updated At: $(Get-Date -Format s)
- Overall Readiness: $(Get-ResolvedValue -Value $overallReadiness)
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Release Readiness Audit: $resolvedAuditPath
- Readiness State: $(Get-ResolvedValue -Value $readinessState)
- Validation Matrix State: $(Get-ResolvedValue -Value $validationState)
- Candidate State: $(Get-ResolvedValue -Value $candidateState)
- Candidate Version: $(Get-ResolvedValue -Value $candidateVersion)
- Release Evidence Audit: $(Get-ResolvedValue -Value $releaseEvidenceAuditPath)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Soft Gate State: $(Get-ResolvedValue -Value $softGateState)
- Soft Gate Result: $(Get-ResolvedValue -Value $softGateResult)
- Strict Gate State: $(Get-ResolvedValue -Value $strictGateState)
- Strict Gate Result: $(Get-ResolvedValue -Value $strictGateResult)
- Release Candidate Path: $(Get-ResolvedValue -Value $releaseCandidatePath)
- Release Manifest: $(Get-ResolvedValue -Value $releaseManifestPath)
- Audited At: $(Get-ResolvedValue -Value $auditedAt)

## Summary
$(Format-Items -Items $summaryItems)

## Recommendation
$(switch ($overallReadiness) {
    "published" { "- keep this summary as the current published release trail reference." }
    "ready-to-publish" { "- validate GitHub release context, then publish when release notes are final." }
    "ready-for-strict-release-candidate" { "- run strict release-candidate prep from the same evidence chain." }
    "ready-for-soft-release-candidate" { "- tighten exact evidence coverage before you rely on strict RC gating." }
    default { "- close the missing evidence or readiness gaps, then rerun `scripts/audit-release-readiness.ps1`." }
})
"@

$currentContent = @"
# Lumina-OS Current Release Readiness

- Updated At: $(Get-Date -Format s)
- Overall Readiness: $(Get-ResolvedValue -Value $overallReadiness)
- Latest Summary: $summaryPath
- Release Readiness Audit: $resolvedAuditPath
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Candidate State: $(Get-ResolvedValue -Value $candidateState)
- Soft Gate State: $(Get-ResolvedValue -Value $softGateState)
- Strict Gate State: $(Get-ResolvedValue -Value $strictGateState)

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(switch ($overallReadiness) {
    "published" { "- use this file as the current release-readiness trace until the next candidate cycle starts." }
    "ready-to-publish" { "- publish or archive the current candidate when the wording and assets are final." }
    "ready-for-strict-release-candidate" { "- prepare a strict release candidate from this evidence chain." }
    "ready-for-soft-release-candidate" { "- tighten the exact evidence coverage before a strict RC pass." }
    default { "- finish the missing readiness work, then rerun `scripts/audit-release-readiness.ps1`." }
})
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Updated current release readiness:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $overallReadiness"
}
