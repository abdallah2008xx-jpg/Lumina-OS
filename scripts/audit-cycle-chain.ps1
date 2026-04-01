param(
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$SessionPath = "",
    [string]$AuditPath = "",
    [string]$BlockerPath = "",
    [string]$ReadinessPath = "",
    [string]$ValidationMatrixPath = "",
    [string]$RunLabel = "",
    [switch]$OutputPathOnly,
    [switch]$FailOnMismatch,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-LatestTrackedFile {
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

function Get-FileByRunLabel {
    param(
        [string]$Path,
        [string]$Filter,
        [string]$RunLabel
    )

    if ([string]::IsNullOrWhiteSpace($RunLabel) -or -not (Test-Path $Path)) {
        return $null
    }

    $escapedRunLabel = [regex]::Escape($RunLabel)

    return Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "CURRENT-*.md" } |
        Where-Object {
            if ($_.Name -match $escapedRunLabel) {
                return $true
            }

            $content = Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue
            return ($content -match ("(?m)^- Run Label: " + $escapedRunLabel + "$"))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
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
    $safe = [regex]::Replace($safe, "[^a-z0-9\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

function Add-ListItem {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        $Target.Add($Message) | Out-Null
    }
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
}

function Get-DocInfo {
    param(
        [string]$Label,
        [string]$Path
    )

    $exists = -not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path $Path)
    $content = if ($exists) { Get-Content -Raw $Path } else { "" }

    return [pscustomobject]@{
        Label = $Label
        Path = if ([string]::IsNullOrWhiteSpace($Path)) { "not-recorded-yet" } else { $Path }
        Exists = $exists
        Content = $content
        RunLabel = Get-MetadataValue -Content $content -Label "Run Label"
        Mode = Get-MetadataValue -Content $content -Label "Mode"
    }
}

function Test-LinkMatch {
    param(
        [string]$Label,
        [string]$RecordedPath,
        [string]$ExpectedPath,
        [System.Collections.Generic.List[string]]$Failures
    )

    if ([string]::IsNullOrWhiteSpace($RecordedPath) -or $RecordedPath -in @("not-recorded-yet", "not-found")) {
        Add-ListItem -Target $Failures -Message "$Label is missing from the linked metadata."
        return
    }

    if ([string]::IsNullOrWhiteSpace($ExpectedPath) -or -not (Test-Path $ExpectedPath)) {
        Add-ListItem -Target $Failures -Message "$Label cannot be validated because the expected path is missing: $ExpectedPath"
        return
    }

    $resolvedRecorded = if (Test-Path $RecordedPath) { (Resolve-Path $RecordedPath).Path } else { $RecordedPath }
    $resolvedExpected = (Resolve-Path $ExpectedPath).Path

    if ($resolvedRecorded -ne $resolvedExpected) {
        Add-ListItem -Target $Failures -Message "$Label points to a different file: $resolvedRecorded <> $resolvedExpected"
    }
}

function Get-ModeState {
    param(
        [string]$Content,
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($Content) -or [string]::IsNullOrWhiteSpace($Mode)) {
        return ""
    }

    $pattern = "(?m)^- " + [regex]::Escape($Mode) + ": (.+)$"
    $match = [regex]::Match($Content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return ""
}

$resolvedBuildManifestPath = $BuildManifestPath
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedBuildManifestPath = $candidate.FullName
    }
}

$resolvedVmReportPath = $VmReportPath
if ([string]::IsNullOrWhiteSpace($resolvedVmReportPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedVmReportPath = $candidate.FullName
    }
}

$resolvedSessionPath = $SessionPath
if ([string]::IsNullOrWhiteSpace($resolvedSessionPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedSessionPath = $candidate.FullName
    }
}

$resolvedAuditPath = $AuditPath
if ([string]::IsNullOrWhiteSpace($resolvedAuditPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedAuditPath = $candidate.FullName
    }
}

$resolvedBlockerPath = $BlockerPath
if ([string]::IsNullOrWhiteSpace($resolvedBlockerPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\blockers") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\blockers") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedBlockerPath = $candidate.FullName
    }
}

$resolvedReadinessPath = $ReadinessPath
if ([string]::IsNullOrWhiteSpace($resolvedReadinessPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestTrackedFile -Path (Join-Path $RepoRoot "status\readiness") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\readiness") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedReadinessPath = $candidate.FullName
    }
}

$resolvedValidationMatrixPath = if ([string]::IsNullOrWhiteSpace($ValidationMatrixPath)) {
    Join-Path $RepoRoot "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md"
}
else {
    $ValidationMatrixPath
}

$currentBlockersPath = Join-Path $RepoRoot "status\blockers\CURRENT-BLOCKERS.md"
$currentReadinessPath = Join-Path $RepoRoot "status\readiness\CURRENT-READINESS.md"

$buildInfo = Get-DocInfo -Label "Build Manifest" -Path $resolvedBuildManifestPath
$vmInfo = Get-DocInfo -Label "VM Report" -Path $resolvedVmReportPath
$sessionInfo = Get-DocInfo -Label "Session Summary" -Path $resolvedSessionPath
$auditInfo = Get-DocInfo -Label "Session Audit" -Path $resolvedAuditPath
$blockerInfo = Get-DocInfo -Label "Blocker Review" -Path $resolvedBlockerPath
$readinessInfo = Get-DocInfo -Label "Readiness Snapshot" -Path $resolvedReadinessPath
$validationInfo = Get-DocInfo -Label "Validation Matrix" -Path $resolvedValidationMatrixPath
$currentBlockersInfo = Get-DocInfo -Label "Current Blockers" -Path $currentBlockersPath
$currentReadinessInfo = Get-DocInfo -Label "Current Readiness" -Path $currentReadinessPath

$resolvedRunLabel = if (-not [string]::IsNullOrWhiteSpace($RunLabel)) { $RunLabel.Trim() } else { "" }
foreach ($candidateRunLabel in @($sessionInfo.RunLabel, $buildInfo.RunLabel, $vmInfo.RunLabel, $auditInfo.RunLabel, $blockerInfo.RunLabel, $readinessInfo.RunLabel)) {
    if ([string]::IsNullOrWhiteSpace($resolvedRunLabel) -and -not [string]::IsNullOrWhiteSpace($candidateRunLabel)) {
        $resolvedRunLabel = $candidateRunLabel
    }
}

$resolvedMode = ""
foreach ($candidateMode in @($sessionInfo.Mode, $vmInfo.Mode, $buildInfo.Mode, $readinessInfo.Mode)) {
    if ([string]::IsNullOrWhiteSpace($resolvedMode) -and -not [string]::IsNullOrWhiteSpace($candidateMode)) {
        $resolvedMode = $candidateMode
    }
}

$dateLabel = Get-MetadataValue -Content $sessionInfo.Content -Label "Date"
if ([string]::IsNullOrWhiteSpace($dateLabel)) {
    $dateLabel = Get-Date -Format "yyyy-MM-dd"
}

$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportSuffix = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { $timeStamp } else { $safeRunLabel }
$reportDir = Join-Path $RepoRoot ("status\cycle-chain-audits\" + $dateLabel)
$reportPath = Join-Path $reportDir ("cycle-chain-audit-" + $reportSuffix + ".md")
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$notes = [System.Collections.Generic.List[string]]::new()

foreach ($doc in @($buildInfo, $vmInfo, $sessionInfo, $auditInfo, $blockerInfo, $readinessInfo, $validationInfo)) {
    if (-not $doc.Exists) {
        Add-ListItem -Target $failures -Message ($doc.Label + " is missing: " + $doc.Path)
    }
}

foreach ($doc in @($buildInfo, $vmInfo, $sessionInfo, $auditInfo, $blockerInfo, $readinessInfo)) {
    if (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
        if ([string]::IsNullOrWhiteSpace($doc.RunLabel)) {
            Add-ListItem -Target $failures -Message ($doc.Label + " does not record a Run Label.")
        }
        elseif ($doc.RunLabel -ne $resolvedRunLabel) {
            Add-ListItem -Target $failures -Message ($doc.Label + " Run Label does not match the cycle: " + $doc.RunLabel + " <> " + $resolvedRunLabel)
        }
    }
}

foreach ($doc in @($buildInfo, $vmInfo, $sessionInfo, $readinessInfo)) {
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode) -and $doc.Exists) {
        if ([string]::IsNullOrWhiteSpace($doc.Mode)) {
            Add-ListItem -Target $failures -Message ($doc.Label + " does not record a Mode.")
        }
        elseif ($doc.Mode -ne $resolvedMode) {
            Add-ListItem -Target $failures -Message ($doc.Label + " Mode does not match the cycle: " + $doc.Mode + " <> " + $resolvedMode)
        }
    }
}

if ($sessionInfo.Exists) {
    Test-LinkMatch -Label "Session Summary -> Build Manifest" -RecordedPath (Get-MetadataValue -Content $sessionInfo.Content -Label "Build Manifest") -ExpectedPath $resolvedBuildManifestPath -Failures $failures
    Test-LinkMatch -Label "Session Summary -> VM Report" -RecordedPath (Get-MetadataValue -Content $sessionInfo.Content -Label "VM Report") -ExpectedPath $resolvedVmReportPath -Failures $failures
}

if ($auditInfo.Exists) {
    Test-LinkMatch -Label "Session Audit -> Session Summary" -RecordedPath (Get-MetadataValue -Content $auditInfo.Content -Label "Session Path") -ExpectedPath $resolvedSessionPath -Failures $failures
}

if ($blockerInfo.Exists) {
    Test-LinkMatch -Label "Blocker Review -> Session Summary" -RecordedPath (Get-MetadataValue -Content $blockerInfo.Content -Label "Session Path") -ExpectedPath $resolvedSessionPath -Failures $failures
    Test-LinkMatch -Label "Blocker Review -> VM Report" -RecordedPath (Get-MetadataValue -Content $blockerInfo.Content -Label "VM Report Path") -ExpectedPath $resolvedVmReportPath -Failures $failures
    Test-LinkMatch -Label "Blocker Review -> Session Audit" -RecordedPath (Get-MetadataValue -Content $blockerInfo.Content -Label "Audit Path") -ExpectedPath $resolvedAuditPath -Failures $failures
}

if ($readinessInfo.Exists) {
    Test-LinkMatch -Label "Readiness Snapshot -> Build Manifest" -RecordedPath (Get-MetadataValue -Content $readinessInfo.Content -Label "Build Manifest") -ExpectedPath $resolvedBuildManifestPath -Failures $failures
    Test-LinkMatch -Label "Readiness Snapshot -> Session Summary" -RecordedPath (Get-MetadataValue -Content $readinessInfo.Content -Label "Session Summary") -ExpectedPath $resolvedSessionPath -Failures $failures
    Test-LinkMatch -Label "Readiness Snapshot -> Session Audit" -RecordedPath (Get-MetadataValue -Content $readinessInfo.Content -Label "Session Audit") -ExpectedPath $resolvedAuditPath -Failures $failures
    Test-LinkMatch -Label "Readiness Snapshot -> Blocker Review" -RecordedPath (Get-MetadataValue -Content $readinessInfo.Content -Label "Blocker Source") -ExpectedPath $resolvedBlockerPath -Failures $failures
}

$auditState = Get-MetadataValue -Content $auditInfo.Content -Label "Overall Status"
$blockerState = Get-MetadataValue -Content $blockerInfo.Content -Label "Overall State"
$readinessState = Get-MetadataValue -Content $readinessInfo.Content -Label "Readiness State"
$validationState = Get-MetadataValue -Content $validationInfo.Content -Label "Overall State"
$modeValidationState = Get-ModeState -Content $validationInfo.Content -Mode $resolvedMode

if ($auditState -eq "warning") {
    Add-ListItem -Target $warnings -Message "Session audit still reports warning."
}
elseif ($auditState -eq "fail") {
    Add-ListItem -Target $warnings -Message "Session audit reports fail; the chain exists but the run itself is not clean yet."
}

if ($blockerState -in @("blocked", "attention")) {
    Add-ListItem -Target $warnings -Message ("Blocker review state is " + $blockerState + ".")
}

if ($readinessState -in @("blocked", "attention", "needs-build", "needs-vm-cycle", "needs-audit", "needs-blocker-sync", "review-required", "needs-build-output")) {
    Add-ListItem -Target $warnings -Message ("Readiness state is " + $readinessState + ".")
}

if ([string]::IsNullOrWhiteSpace($modeValidationState)) {
    Add-ListItem -Target $warnings -Message "Validation matrix does not expose a per-mode state for the current mode."
}
else {
    Add-ListItem -Target $notes -Message ("Validation matrix state for " + $resolvedMode + ": " + $modeValidationState)
}

if ($currentBlockersInfo.Exists) {
    $currentBlockerRunLabel = Get-MetadataValue -Content $currentBlockersInfo.Content -Label "Run Label"
    $currentBlockerLatestReview = Get-MetadataValue -Content $currentBlockersInfo.Content -Label "Latest Review"

    if (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel) -and
        -not [string]::IsNullOrWhiteSpace($currentBlockerRunLabel) -and
        $currentBlockerRunLabel -ne $resolvedRunLabel) {
        Add-ListItem -Target $warnings -Message ("Current blockers now point at a different run label: " + $currentBlockerRunLabel)
    }

    if (-not [string]::IsNullOrWhiteSpace($currentBlockerLatestReview) -and
        $currentBlockerLatestReview -notin @("not-recorded-yet", "not-found") -and
        $blockerInfo.Exists) {
        Test-LinkMatch -Label "Current Blockers -> Latest Review" -RecordedPath $currentBlockerLatestReview -ExpectedPath $resolvedBlockerPath -Failures $warnings
    }
}

if ($currentReadinessInfo.Exists) {
    $currentReadinessRunLabel = Get-MetadataValue -Content $currentReadinessInfo.Content -Label "Run Label"
    $currentReadinessSnapshot = Get-MetadataValue -Content $currentReadinessInfo.Content -Label "Latest Snapshot"

    if (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel) -and
        -not [string]::IsNullOrWhiteSpace($currentReadinessRunLabel) -and
        $currentReadinessRunLabel -ne $resolvedRunLabel) {
        Add-ListItem -Target $warnings -Message ("Current readiness now points at a different run label: " + $currentReadinessRunLabel)
    }

    if (-not [string]::IsNullOrWhiteSpace($currentReadinessSnapshot) -and
        $currentReadinessSnapshot -notin @("not-recorded-yet", "not-found") -and
        $readinessInfo.Exists) {
        Test-LinkMatch -Label "Current Readiness -> Latest Snapshot" -RecordedPath $currentReadinessSnapshot -ExpectedPath $resolvedReadinessPath -Failures $warnings
    }
}

$overallStatus = if ($failures.Count -gt 0) {
    "fail"
}
elseif ($warnings.Count -gt 0) {
    "warning"
}
else {
    "pass"
}

$documentLines = @(
    "- Build Manifest: " + $buildInfo.Path,
    "- VM Report: " + $vmInfo.Path,
    "- Session Summary: " + $sessionInfo.Path,
    "- Session Audit: " + $auditInfo.Path,
    "- Blocker Review: " + $blockerInfo.Path,
    "- Readiness Snapshot: " + $readinessInfo.Path,
    "- Validation Matrix: " + $validationInfo.Path
) -join "`r`n"

$metadataNotes = [System.Collections.Generic.List[string]]::new()
if (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    $metadataNotes.Add("Expected Run Label: $resolvedRunLabel") | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
    $metadataNotes.Add("Expected Mode: $resolvedMode") | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($auditState)) {
    $metadataNotes.Add("Audit State: $auditState") | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($blockerState)) {
    $metadataNotes.Add("Blocker State: $blockerState") | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($readinessState)) {
    $metadataNotes.Add("Readiness State: $readinessState") | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($validationState)) {
    $metadataNotes.Add("Validation Matrix Overall State: $validationState") | Out-Null
}

$content = @"
# Lumina-OS Cycle Chain Audit

- Audited At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Mode: $(if ([string]::IsNullOrWhiteSpace($resolvedMode)) { "unknown" } else { $resolvedMode })
- Overall Status: $overallStatus

## Linked Documents
$documentLines

## Metadata Notes
$(Format-Items -Items $metadataNotes)

## Notes
$(Format-Items -Items $notes)

## Warnings
$(Format-Items -Items $warnings)

## Failures
$(Format-Items -Items $failures)

## Recommendation
$(switch ($overallStatus) {
    "fail" { "- fix the missing or mismatched evidence links before promoting this run toward release." }
    "warning" { "- the evidence chain exists, but review the warning items before treating this run as the clean reference candidate." }
    default { "- the evidence chain is internally consistent and can be used as the reference trail for release preparation." }
})
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

if ($FailOnMismatch -and $overallStatus -eq "fail") {
    Write-Error "Lumina-OS cycle chain audit failed. See: $reportPath"
}

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created Lumina-OS cycle chain audit:"
    Write-Host $reportPath
    Write-Host "Overall status: $overallStatus"
}
