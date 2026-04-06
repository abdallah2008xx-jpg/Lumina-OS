param(
    [string]$StatusPath = "",
    [string]$ReadinessPath = "",
    [string]$ValidationMatrixPath = "",
    [string]$ReleaseCandidatePath = "",
    [string]$ReleaseEvidencePackPath = "",
    [string]$ReleaseEvidenceAuditPath = "",
    [string]$ReleaseReadinessAuditPath = "",
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

function Get-SectionItems {
    param(
        [string]$Content,
        [string]$Heading
    )

    $items = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $items
    }

    $pattern = "(?s)^## " + [regex]::Escape($Heading) + "\r?\n(?<body>.*?)(?=^## |\z)"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $match.Success) {
        return $items
    }

    foreach ($rawLine in ($match.Groups["body"].Value -split "`r?`n")) {
        $line = $rawLine.Trim()
        if ($line.StartsWith("- ")) {
            $items.Add($line.Substring(2).Trim()) | Out-Null
        }
    }

    return $items
}

function Get-TopItems {
    param(
        [System.Collections.Generic.List[string]]$Items,
        [int]$Count,
        [switch]$FromEnd
    )

    $result = [System.Collections.Generic.List[string]]::new()
    if ($Items.Count -eq 0) {
        return $result
    }

    if ($FromEnd.IsPresent) {
        $startIndex = [Math]::Max(0, $Items.Count - $Count)
        for ($index = $startIndex; $index -lt $Items.Count; $index++) {
            $result.Add($Items[$index]) | Out-Null
        }
    }
    else {
        for ($index = 0; $index -lt [Math]::Min($Count, $Items.Count); $index++) {
            $result.Add($Items[$index]) | Out-Null
        }
    }

    return $result
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
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

function Get-LatestFile {
    param(
        [string]$Path,
        [string]$Filter
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    return Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "CURRENT-*.md" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

$resolvedStatusPath = if ([string]::IsNullOrWhiteSpace($StatusPath)) {
    Join-Path $RepoRoot "status\CURRENT-STATUS.md"
}
else {
    $StatusPath
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

$resolvedReleaseEvidencePackPath = if ([string]::IsNullOrWhiteSpace($ReleaseEvidencePackPath)) {
    $currentPackPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-PACK.md"
    if (Test-Path $currentPackPath) { $currentPackPath } else { "" }
}
else {
    $ReleaseEvidencePackPath
}

$resolvedReleaseEvidenceAuditPath = if ([string]::IsNullOrWhiteSpace($ReleaseEvidenceAuditPath)) {
    $latestAudit = Get-LatestFile -Path (Join-Path $RepoRoot "status\releases") -Filter "release-evidence-audit.md"
    if ($latestAudit) { $latestAudit.FullName } else { "" }
}
else {
    $ReleaseEvidenceAuditPath
}

$resolvedReleaseReadinessAuditPath = if ([string]::IsNullOrWhiteSpace($ReleaseReadinessAuditPath)) {
    $currentReadinessPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-READINESS.md"
    if (Test-Path $currentReadinessPath) {
        $currentReadinessPath
    }
    else {
        $latestReadinessAudit = Get-LatestFile -Path (Join-Path $RepoRoot "status\releases") -Filter "release-readiness-audit.md"
        if ($latestReadinessAudit) { $latestReadinessAudit.FullName } else { "" }
    }
}
else {
    $ReleaseReadinessAuditPath
}

foreach ($requiredPath in @($resolvedStatusPath, $resolvedReadinessPath, $resolvedValidationMatrixPath, $resolvedReleaseCandidatePath)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required status input: $requiredPath"
    }
}

$statusContent = Get-Content -Raw $resolvedStatusPath
$readinessContent = Get-Content -Raw $resolvedReadinessPath
$validationContent = Get-Content -Raw $resolvedValidationMatrixPath
$releaseCandidateContent = Get-Content -Raw $resolvedReleaseCandidatePath
$releaseEvidencePackContent = if (-not [string]::IsNullOrWhiteSpace($resolvedReleaseEvidencePackPath) -and (Test-Path $resolvedReleaseEvidencePackPath)) {
    Get-Content -Raw $resolvedReleaseEvidencePackPath
}
else {
    ""
}
$releaseEvidenceAuditContent = if (-not [string]::IsNullOrWhiteSpace($resolvedReleaseEvidenceAuditPath) -and (Test-Path $resolvedReleaseEvidenceAuditPath)) {
    Get-Content -Raw $resolvedReleaseEvidenceAuditPath
}
else {
    ""
}
$releaseReadinessAuditContent = if (-not [string]::IsNullOrWhiteSpace($resolvedReleaseReadinessAuditPath) -and (Test-Path $resolvedReleaseReadinessAuditPath)) {
    Get-Content -Raw $resolvedReleaseReadinessAuditPath
}
else {
    ""
}

$completedItems = Get-SectionItems -Content $statusContent -Heading "Completed"
$nextItems = Get-SectionItems -Content $statusContent -Heading "Next"
$recentProgress = Get-TopItems -Items $completedItems -Count 5 -FromEnd
$immediateNext = Get-TopItems -Items $nextItems -Count 5

$readinessState = Get-MetadataValue -Content $readinessContent -Label "Readiness State"
$validationState = Get-MetadataValue -Content $validationContent -Label "Overall State"
$candidateState = Get-MetadataValue -Content $releaseCandidateContent -Label "Candidate State"
$evidencePackState = Get-MetadataValue -Content $releaseEvidencePackContent -Label "Evidence Pack State"
$evidenceSoftGateState = Get-MetadataValue -Content $releaseEvidenceAuditContent -Label "Soft Gate State"
$evidenceStrictGateState = Get-MetadataValue -Content $releaseEvidenceAuditContent -Label "Strict Gate State"
$evidenceAuditRunLabel = Get-MetadataValue -Content $releaseEvidenceAuditContent -Label "Run Label"
$releaseReadinessState = Get-MetadataValue -Content $releaseReadinessAuditContent -Label "Overall Readiness"
$runLabel = Get-FirstNonEmptyValue @(
    $evidenceAuditRunLabel,
    (Get-MetadataValue -Content $releaseEvidencePackContent -Label "Run Label"),
    (Get-MetadataValue -Content $releaseReadinessAuditContent -Label "Run Label"),
    (Get-MetadataValue -Content $releaseCandidateContent -Label "Run Label"),
    (Get-MetadataValue -Content $readinessContent -Label "Run Label")
)
$version = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $releaseEvidencePackContent -Label "Release Version"),
    (Get-MetadataValue -Content $releaseCandidateContent -Label "Version")
)

$headline = switch ($true) {
    { $candidateState -eq "published" } { "Lumina-OS now has a published release candidate trail with linked release evidence."; break }
    { $candidateState -eq "ready-to-publish" } { "Lumina-OS now has a release candidate prepared and validated, pending publish."; break }
    { $readinessState -eq "needs-vm-validation" -or $validationState -eq "builds-succeeded-awaiting-vm" } { "Lumina-OS has completed its first successful remote ISO build and is now moving into VM validation."; break }
    { $readinessState -eq "blocked" -or $validationState -eq "blocked" } { "Lumina-OS completed a real VM validation cycle and surfaced concrete runtime blockers that should be fixed before promotion."; break }
    { $readinessState -eq "ready-for-next-stage" -and $validationState -notin @("needs-first-build", "blocked") } { "Lumina-OS has a clean internal validation trail and is ready for the next execution stage."; break }
    default { "Lumina-OS has strong build/test/release workflow coverage and is waiting on the first real Arch-side execution cycle." }
}

$shareableSummary = [System.Collections.Generic.List[string]]::new()
$shareableSummary.Add($headline) | Out-Null
$shareableSummary.Add("Readiness state: $(Get-ResolvedPathOrDefault -Value $readinessState -DefaultValue "not-recorded-yet")") | Out-Null
$shareableSummary.Add("Validation matrix state: $(Get-ResolvedPathOrDefault -Value $validationState -DefaultValue "not-recorded-yet")") | Out-Null
$shareableSummary.Add("Release candidate state: $(Get-ResolvedPathOrDefault -Value $candidateState -DefaultValue "not-recorded-yet")") | Out-Null

if (-not [string]::IsNullOrWhiteSpace($evidencePackState)) {
    $shareableSummary.Add("Current evidence pack: $evidencePackState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($releaseReadinessState)) {
    $shareableSummary.Add("Release readiness audit: $releaseReadinessState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($evidenceSoftGateState)) {
    $shareableSummary.Add("Release evidence soft gate: $evidenceSoftGateState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($evidenceStrictGateState)) {
    $shareableSummary.Add("Release evidence strict gate: $evidenceStrictGateState") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($version) -and $version -ne "not-recorded-yet") {
    $shareableSummary.Add("Current tracked release version: $version") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and $runLabel -ne "not-recorded-yet") {
    $shareableSummary.Add("Current tracked run label: $runLabel") | Out-Null
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$shareableDir = Join-Path $RepoRoot ("status\shareable-updates\" + $dateStamp)
$shareableSnapshotPath = Join-Path $shareableDir ("shareable-update-" + $timeStamp + ".md")
$currentShareablePath = Join-Path $RepoRoot "status\SHAREABLE-UPDATE.md"

New-Item -ItemType Directory -Force -Path $shareableDir | Out-Null

$content = @"
# Lumina-OS Shareable Update

- Generated At: $(Get-Date -Format s)
- Readiness State: $(Get-ResolvedPathOrDefault -Value $readinessState -DefaultValue "not-recorded-yet")
- Validation Matrix State: $(Get-ResolvedPathOrDefault -Value $validationState -DefaultValue "not-recorded-yet")
- Release Candidate State: $(Get-ResolvedPathOrDefault -Value $candidateState -DefaultValue "not-recorded-yet")
- Release Evidence Pack: $(Get-ResolvedPathOrDefault -Value $resolvedReleaseEvidencePackPath -DefaultValue "not-recorded-yet")
- Release Evidence Pack State: $(Get-ResolvedPathOrDefault -Value $evidencePackState -DefaultValue "not-recorded-yet")
- Release Evidence Audit: $(Get-ResolvedPathOrDefault -Value $resolvedReleaseEvidenceAuditPath -DefaultValue "not-recorded-yet")
- Release Readiness Audit: $(Get-ResolvedPathOrDefault -Value $resolvedReleaseReadinessAuditPath -DefaultValue "not-recorded-yet")
- Release Readiness State: $(Get-ResolvedPathOrDefault -Value $releaseReadinessState -DefaultValue "not-recorded-yet")
- Release Evidence Soft Gate: $(Get-ResolvedPathOrDefault -Value $evidenceSoftGateState -DefaultValue "not-recorded-yet")
- Release Evidence Strict Gate: $(Get-ResolvedPathOrDefault -Value $evidenceStrictGateState -DefaultValue "not-recorded-yet")
- Current Run Label: $(Get-ResolvedPathOrDefault -Value $runLabel -DefaultValue "not-recorded-yet")
- Current Version: $(Get-ResolvedPathOrDefault -Value $version -DefaultValue "not-recorded-yet")

## Current State
$(Format-Items -Items $shareableSummary)

## Recent Progress
$(Format-Items -Items $recentProgress)

## What Is Ready
- The core build/test/release workflow is scaffolded and validated locally.
- Linked evidence now covers build manifests, VM reports, session audits, blockers, readiness, validation matrix, and release-candidate state.
- Release evidence audit can now show soft vs strict gating before candidate prep.
- Release readiness audit can now summarize the final go/no-go state before publish.
- GitHub publish now has local release-context validation before release creation.

## What Is Still Missing
- The recorded runtime blockers from the latest real VM cycle still need fixes.
- The `login-test` mode still needs the same level of real VM coverage.
- The first real release candidate built from a real ISO is still pending.
- The first real published Lumina-OS release on GitHub.

## Immediate Next Step
$(Format-Items -Items $immediateNext)
"@

Set-Content -Path $shareableSnapshotPath -Value $content -Encoding UTF8
Set-Content -Path $currentShareablePath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $shareableSnapshotPath
}
else {
    Write-Host "Updated Lumina-OS shareable update:"
    Write-Host "Snapshot: $shareableSnapshotPath"
    Write-Host "Current:  $currentShareablePath"
}
