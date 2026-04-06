param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "stable",
    [string]$RunLabel = "",
    [string]$IsoPath = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$LoginTestReportPath = "",
    [string]$InstallReportPath = "",
    [string]$HardwareReportPath = "",
    [string]$SessionPath = "",
    [string]$AuditPath = "",
    [string]$CycleChainAuditPath = "",
    [string]$ReadinessPath = "",
    [string]$ValidationMatrixPath = "",
    [string]$ReleaseCandidatePath = "",
    [string]$ReleaseEvidenceAuditPath = "",
    [switch]$AllowAttentionState,
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

function Get-FirstNonEmptyValue {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "not-recorded-yet") {
            return $value
        }
    }

    return ""
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
}

$releaseEvidenceAuditScript = Join-Path $PSScriptRoot "audit-release-evidence.ps1"
if (-not (Test-Path $releaseEvidenceAuditScript)) {
    throw "Missing helper: $releaseEvidenceAuditScript"
}

$resolvedReadinessPath = if ([string]::IsNullOrWhiteSpace($ReadinessPath)) {
    Join-Path $RepoRoot "status\readiness\CURRENT-READINESS.md"
}
else {
    $ReadinessPath
}

$resolvedValidationMatrixPath = if ([string]::IsNullOrWhiteSpace($ValidationMatrixPath)) {
    Join-Path $RepoRoot "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md"
}
else {
    $ValidationMatrixPath
}

$resolvedReleaseCandidatePath = if ([string]::IsNullOrWhiteSpace($ReleaseCandidatePath)) {
    Join-Path $RepoRoot "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md"
}
else {
    $ReleaseCandidatePath
}

$resolvedReleaseEvidenceAuditPath = $ReleaseEvidenceAuditPath
if ([string]::IsNullOrWhiteSpace($resolvedReleaseEvidenceAuditPath) -or -not (Test-Path $resolvedReleaseEvidenceAuditPath)) {
    $evidenceAuditArgs = @{
        Version = $Version
        Mode = $Mode
        RunLabel = $RunLabel
        IsoPath = $IsoPath
        BuildManifestPath = $BuildManifestPath
        VmReportPath = $VmReportPath
        LoginTestReportPath = $LoginTestReportPath
        InstallReportPath = $InstallReportPath
        HardwareReportPath = $HardwareReportPath
        SessionPath = $SessionPath
        AuditPath = $AuditPath
        CycleChainAuditPath = $CycleChainAuditPath
        ReadinessPath = $resolvedReadinessPath
        ValidationMatrixPath = $resolvedValidationMatrixPath
        RepoRoot = $RepoRoot
        OutputPathOnly = $true
    }

    if ($AllowAttentionState.IsPresent) {
        $evidenceAuditArgs["AllowAttentionState"] = $true
    }

    $resolvedReleaseEvidenceAuditPath = & $releaseEvidenceAuditScript @evidenceAuditArgs
}

if (-not $resolvedReleaseEvidenceAuditPath -or -not (Test-Path $resolvedReleaseEvidenceAuditPath)) {
    throw "Unable to prepare or resolve release evidence audit."
}

$resolvedReleaseEvidenceAuditPath = (Resolve-Path $resolvedReleaseEvidenceAuditPath).Path
$releaseDir = Split-Path -Parent $resolvedReleaseEvidenceAuditPath
$readinessAuditPath = Join-Path $releaseDir "release-readiness-audit.md"

$readinessContent = if (Test-Path $resolvedReadinessPath) { Get-Content -Raw $resolvedReadinessPath } else { "" }
$validationContent = if (Test-Path $resolvedValidationMatrixPath) { Get-Content -Raw $resolvedValidationMatrixPath } else { "" }
$candidateContent = if (Test-Path $resolvedReleaseCandidatePath) { Get-Content -Raw $resolvedReleaseCandidatePath } else { "" }
$evidenceAuditContent = Get-Content -Raw $resolvedReleaseEvidenceAuditPath

$resolvedRunLabel = Get-FirstNonEmptyValue @(
    $RunLabel,
    (Get-MetadataValue -Content $evidenceAuditContent -Label "Run Label"),
    (Get-MetadataValue -Content $candidateContent -Label "Run Label"),
    (Get-MetadataValue -Content $readinessContent -Label "Run Label")
)

$readinessState = Get-MetadataValue -Content $readinessContent -Label "Readiness State"
$validationState = Get-MetadataValue -Content $validationContent -Label "Overall State"
$candidateState = Get-MetadataValue -Content $candidateContent -Label "Candidate State"
$candidateVersion = Get-MetadataValue -Content $candidateContent -Label "Version"
$candidateManifestPath = Get-MetadataValue -Content $candidateContent -Label "Release Manifest"
$softGateState = Get-MetadataValue -Content $evidenceAuditContent -Label "Soft Gate State"
$softGateResult = Get-MetadataValue -Content $evidenceAuditContent -Label "Soft Gate Result"
$strictGateState = Get-MetadataValue -Content $evidenceAuditContent -Label "Strict Gate State"
$strictGateResult = Get-MetadataValue -Content $evidenceAuditContent -Label "Strict Gate Result"

$softReady = (
    $softGateState -eq "passed" -and
    $readinessState -eq "ready-for-next-stage" -and
    $validationState -notin @("blocked", "needs-build", "needs-first-build", "needs-audit")
)

$strictReady = $softReady -and $strictGateState -eq "passed"

$overallReadiness = switch ($true) {
    { $candidateState -eq "published" -and $strictReady } { "published"; break }
    { $candidateState -eq "ready-to-publish" -and $strictReady } { "ready-to-publish"; break }
    { $strictReady } { "ready-for-strict-release-candidate"; break }
    { $softReady } { "ready-for-soft-release-candidate"; break }
    default { "not-ready" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
$nextItems = [System.Collections.Generic.List[string]]::new()

if ($softReady) {
    $summaryItems.Add("Soft release evidence is aligned with readiness and validation state.") | Out-Null
}
else {
    $summaryItems.Add("Soft release readiness is still incomplete.") | Out-Null
}

if ($strictReady) {
    $summaryItems.Add("Strict release evidence is exact and ready for a strict RC gate.") | Out-Null
}
else {
    $summaryItems.Add("Strict release evidence is not ready yet.") | Out-Null
}

switch ($overallReadiness) {
    "published" {
        $summaryItems.Add("The tracked release candidate is already published.") | Out-Null
        $nextItems.Add("Review the published release trail and keep the evidence archive linked.") | Out-Null
    }
    "ready-to-publish" {
        $summaryItems.Add("The tracked candidate is ready to publish.") | Out-Null
        $nextItems.Add("Run GitHub release context validation and publish when you are ready.") | Out-Null
    }
    "ready-for-strict-release-candidate" {
        $summaryItems.Add("The evidence set is ready for strict release-candidate preparation.") | Out-Null
        $nextItems.Add("Run prepare-release-candidate.ps1 with -RequireExactEvidenceRunLabel.") | Out-Null
    }
    "ready-for-soft-release-candidate" {
        $summaryItems.Add("The evidence set is ready for a soft release-candidate pass.") | Out-Null
        $nextItems.Add("Tighten install/hardware evidence to exact run-label coverage for a strict gate.") | Out-Null
    }
    default {
        $nextItems.Add("Finish the missing login, install, hardware, or release evidence steps before RC preparation.") | Out-Null
    }
}

if ($softGateState -ne "passed") {
    $nextItems.Add("Review release-evidence-audit.md and close the failing soft-gate items first.") | Out-Null
}

if ($softGateState -eq "passed" -and $strictGateState -ne "passed") {
    $nextItems.Add("Provide exact install and hardware evidence for the same run label to unlock the strict gate.") | Out-Null
}

if ([string]::IsNullOrWhiteSpace($candidateState) -or $candidateState -eq "not-recorded-yet") {
    $nextItems.Add("Prepare a release candidate summary once the evidence chain is acceptable.") | Out-Null
}

$reportContent = @"
# Lumina-OS Release Readiness Audit

- Audited At: $(Get-Date -Format s)
- Version: $Version
- Mode: $Mode
- Run Label: $(Get-ResolvedPathOrDefault -Value $resolvedRunLabel -DefaultValue "not-recorded-yet")
- Overall Readiness: $overallReadiness
- Readiness State: $(Get-ResolvedPathOrDefault -Value $readinessState -DefaultValue "not-recorded-yet")
- Validation Matrix State: $(Get-ResolvedPathOrDefault -Value $validationState -DefaultValue "not-recorded-yet")
- Candidate State: $(Get-ResolvedPathOrDefault -Value $candidateState -DefaultValue "not-recorded-yet")
- Candidate Version: $(Get-ResolvedPathOrDefault -Value $candidateVersion -DefaultValue "not-recorded-yet")
- Release Evidence Audit: $resolvedReleaseEvidenceAuditPath
- Soft Gate State: $(Get-ResolvedPathOrDefault -Value $softGateState -DefaultValue "not-recorded-yet")
- Soft Gate Result: $(Get-ResolvedPathOrDefault -Value $softGateResult -DefaultValue "not-recorded-yet")
- Strict Gate State: $(Get-ResolvedPathOrDefault -Value $strictGateState -DefaultValue "not-recorded-yet")
- Strict Gate Result: $(Get-ResolvedPathOrDefault -Value $strictGateResult -DefaultValue "not-recorded-yet")
- Release Candidate Path: $(Get-ResolvedPathOrDefault -Value $resolvedReleaseCandidatePath -DefaultValue "not-recorded-yet")
- Release Manifest: $(Get-ResolvedPathOrDefault -Value $candidateManifestPath -DefaultValue "not-recorded-yet")

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

Set-Content -Path $readinessAuditPath -Value $reportContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $readinessAuditPath
}
else {
    Write-Host "Audited Lumina-OS release readiness:"
    Write-Host "Readiness Audit: $readinessAuditPath"
    Write-Host "Overall Readiness: $overallReadiness"
}
