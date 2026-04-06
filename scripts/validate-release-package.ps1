param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseManifestPath,
    [switch]$AllowAttentionState,
    [switch]$RequireExactEvidenceRunLabel,
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

function Add-ValidationItem {
    param(
        [System.Collections.Generic.List[string]]$Bucket,
        [string]$Message
    )

    $Bucket.Add($Message) | Out-Null
}

function Resolve-ExistingPath {
    param(
        [string]$Label,
        [string]$Value,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "not-recorded-yet") {
        Add-ValidationItem -Bucket $Errors -Message "$Label is missing from the release manifest."
        return ""
    }

    if (-not (Test-Path $Value)) {
        Add-ValidationItem -Bucket $Errors -Message "$Label does not exist: $Value"
        return ""
    }

    return (Resolve-Path $Value).Path
}

function Get-StateValue {
    param(
        [string]$Content,
        [string[]]$Labels
    )

    foreach ($label in $Labels) {
        $value = Get-MetadataValue -Content $Content -Label $label
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return ""
}

function Test-EvidenceReport {
    param(
        [string]$Label,
        [string]$PathValue,
        [string[]]$StatusLabels,
        [string[]]$PassStates,
        [string[]]$WarningStates,
        [string[]]$ErrorStates,
        [System.Collections.Generic.List[string]]$Errors,
        [System.Collections.Generic.List[string]]$Warnings,
        [System.Collections.Generic.List[string]]$Notes
    )

    $resolvedPath = Resolve-ExistingPath -Label $Label -Value $PathValue -Errors $Errors
    if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
        return @{
            Path = ""
            Status = ""
            RunLabel = ""
            Selection = ""
        }
    }

    $content = Get-Content -Raw $resolvedPath
    $status = Get-StateValue -Content $content -Labels $StatusLabels
    $runLabel = Get-MetadataValue -Content $content -Label "Run Label"
    $selection = Get-MetadataValue -Content $manifestContent -Label ($Label + " Selection")
    $normalizedStatus = if ([string]::IsNullOrWhiteSpace($status)) { "" } else { $status.Trim().ToLowerInvariant() }

    if ([string]::IsNullOrWhiteSpace($normalizedStatus)) {
        Add-ValidationItem -Bucket $Warnings -Message "$Label does not record an explicit status field."
    }
    elseif ($ErrorStates -contains $normalizedStatus) {
        Add-ValidationItem -Bucket $Errors -Message "$Label is not publishable yet: $status"
    }
    elseif ($WarningStates -contains $normalizedStatus) {
        Add-ValidationItem -Bucket $Warnings -Message "$Label requires review before publishing: $status"
    }
    elseif ($PassStates -contains $normalizedStatus) {
        Add-ValidationItem -Bucket $Notes -Message "$Label is acceptable for release gating: $status"
    }
    else {
        Add-ValidationItem -Bucket $Warnings -Message "$Label uses an unrecognized status value: $status"
    }

    return @{
        Path = $resolvedPath
        Status = $status
        RunLabel = $runLabel
        Selection = $selection
    }
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$notes = [System.Collections.Generic.List[string]]::new()

$resolvedManifestPath = Resolve-ExistingPath -Label "Release manifest" -Value $ReleaseManifestPath -Errors $errors
if ([string]::IsNullOrWhiteSpace($resolvedManifestPath)) {
    throw "Release manifest could not be resolved."
}

$manifestContent = Get-Content -Raw $resolvedManifestPath
$version = Get-MetadataValue -Content $manifestContent -Label "Version"
$mode = Get-MetadataValue -Content $manifestContent -Label "Mode"
$runLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$isoPath = Resolve-ExistingPath -Label "ISO Path" -Value (Get-MetadataValue -Content $manifestContent -Label "ISO Path") -Errors $errors
$checksumPath = Resolve-ExistingPath -Label "Checksum File" -Value (Get-MetadataValue -Content $manifestContent -Label "Checksum File") -Errors $errors
$releaseNotesPath = Resolve-ExistingPath -Label "Release Notes" -Value (Get-MetadataValue -Content $manifestContent -Label "Release Notes") -Errors $errors
$buildManifestPath = Resolve-ExistingPath -Label "Build Manifest" -Value (Get-MetadataValue -Content $manifestContent -Label "Build Manifest") -Errors $errors
$vmReportPath = Resolve-ExistingPath -Label "VM Report" -Value (Get-MetadataValue -Content $manifestContent -Label "VM Report") -Errors $errors
$installEvidence = Test-EvidenceReport `
    -Label "Install Report" `
    -PathValue (Get-MetadataValue -Content $manifestContent -Label "Install Report") `
    -StatusLabels @("Overall Status", "Overall State", "Result") `
    -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-release") `
    -WarningStates @("attention", "attention-needed", "warning", "warnings", "review-required") `
    -ErrorStates @("in-progress", "blocked", "block", "fail", "failed", "error", "errors", "pending", "not-started", "not-recorded-yet") `
    -Errors $errors `
    -Warnings $warnings `
    -Notes $notes
$installReportPath = $installEvidence.Path
$installReportState = $installEvidence.Status
$installReportRunLabel = $installEvidence.RunLabel
$installReportSelection = $installEvidence.Selection

$hardwareEvidence = Test-EvidenceReport `
    -Label "Hardware Report" `
    -PathValue (Get-MetadataValue -Content $manifestContent -Label "Hardware Report") `
    -StatusLabels @("Overall Status", "Hardware Readiness", "Overall State", "Result") `
    -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-real-device-smoke", "ready-for-release") `
    -WarningStates @("attention", "attention-needed", "warning", "warnings", "review-required") `
    -ErrorStates @("in-progress", "blocked", "block", "fail", "failed", "error", "errors", "pending", "not-started", "not-recorded-yet", "vm-session-only") `
    -Errors $errors `
    -Warnings $warnings `
    -Notes $notes
$hardwareReportPath = $hardwareEvidence.Path
$hardwareReportState = $hardwareEvidence.Status
$hardwareReportRunLabel = $hardwareEvidence.RunLabel
$hardwareReportSelection = $hardwareEvidence.Selection

$sessionPath = Resolve-ExistingPath -Label "Session Summary" -Value (Get-MetadataValue -Content $manifestContent -Label "Session Summary") -Errors $errors
$auditPath = Resolve-ExistingPath -Label "Session Audit" -Value (Get-MetadataValue -Content $manifestContent -Label "Session Audit") -Errors $errors
$cycleChainAuditPath = Resolve-ExistingPath -Label "Cycle Chain Audit" -Value (Get-MetadataValue -Content $manifestContent -Label "Cycle Chain Audit") -Errors $errors
$readinessPath = Resolve-ExistingPath -Label "Readiness" -Value (Get-MetadataValue -Content $manifestContent -Label "Readiness") -Errors $errors
$validationMatrixPath = Resolve-ExistingPath -Label "Validation Matrix" -Value (Get-MetadataValue -Content $manifestContent -Label "Validation Matrix") -Errors $errors

if ([string]::IsNullOrWhiteSpace($version)) {
    Add-ValidationItem -Bucket $errors -Message "Version is missing from the release manifest."
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($installReportRunLabel) -and
    $installReportRunLabel -ne $runLabel) {
    $message = "Install Report Run Label does not match the release manifest Run Label."
    if ($RequireExactEvidenceRunLabel.IsPresent) {
        Add-ValidationItem -Bucket $errors -Message $message
    }
    else {
        Add-ValidationItem -Bucket $warnings -Message $message
    }
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($hardwareReportRunLabel) -and
    $hardwareReportRunLabel -ne $runLabel) {
    $message = "Hardware Report Run Label does not match the release manifest Run Label."
    if ($RequireExactEvidenceRunLabel.IsPresent) {
        Add-ValidationItem -Bucket $errors -Message $message
    }
    else {
        Add-ValidationItem -Bucket $warnings -Message $message
    }
}

if ($RequireExactEvidenceRunLabel.IsPresent -and -not [string]::IsNullOrWhiteSpace($runLabel)) {
    if (-not [string]::IsNullOrWhiteSpace($installReportSelection) -and $installReportSelection -notin @("exact-run-label", "explicit-path")) {
        Add-ValidationItem -Bucket $errors -Message "Install Report selection is not exact for strict release gating: $installReportSelection"
    }

    if (-not [string]::IsNullOrWhiteSpace($hardwareReportSelection) -and $hardwareReportSelection -notin @("exact-run-label", "explicit-path")) {
        Add-ValidationItem -Bucket $errors -Message "Hardware Report selection is not exact for strict release gating: $hardwareReportSelection"
    }
}

if (-not [string]::IsNullOrWhiteSpace($isoPath) -and -not [string]::IsNullOrWhiteSpace($checksumPath)) {
    $isoHash = (Get-FileHash -Algorithm SHA256 -Path $isoPath).Hash.ToLowerInvariant()
    $checksumContent = Get-Content -Raw $checksumPath

    if ($checksumContent -notmatch [regex]::Escape($isoHash)) {
        Add-ValidationItem -Bucket $errors -Message "SHA256SUMS.txt does not include the current ISO hash."
    }
    else {
        Add-ValidationItem -Bucket $notes -Message "ISO checksum matches the current ISO file."
    }
}

$readinessState = ""
$blockerState = ""
$validationState = ""

if (-not [string]::IsNullOrWhiteSpace($readinessPath)) {
    $readinessContent = Get-Content -Raw $readinessPath
    $readinessState = Get-StateValue -Content $readinessContent -Labels @("Readiness State")

    if ([string]::IsNullOrWhiteSpace($readinessState)) {
        Add-ValidationItem -Bucket $errors -Message "Could not resolve Readiness State from the readiness file."
    }
    elseif ($readinessState -in @("needs-build", "blocked", "not-recorded-yet")) {
        Add-ValidationItem -Bucket $errors -Message "Readiness state is not publishable: $readinessState"
    }
    elseif ($readinessState -eq "attention" -and -not $AllowAttentionState.IsPresent) {
        Add-ValidationItem -Bucket $errors -Message "Readiness state is attention. Re-run with -AllowAttentionState only if this release is intentionally going out with known attention items."
    }
    else {
        Add-ValidationItem -Bucket $notes -Message "Readiness state is acceptable for release gating: $readinessState"
    }

    $blockersPath = Get-MetadataValue -Content $readinessContent -Label "Blocker Source"
    if (-not [string]::IsNullOrWhiteSpace($blockersPath) -and $blockersPath -ne "not-recorded-yet" -and (Test-Path $blockersPath)) {
        $blockersContent = Get-Content -Raw $blockersPath
        $blockerState = Get-StateValue -Content $blockersContent -Labels @("Overall State")

        if ($blockerState -eq "blocked") {
            Add-ValidationItem -Bucket $errors -Message "Current blockers state is blocked."
        }
        elseif (-not [string]::IsNullOrWhiteSpace($blockerState)) {
            Add-ValidationItem -Bucket $notes -Message "Blocker state is acceptable for publish gating: $blockerState"
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($validationMatrixPath)) {
    $validationContent = Get-Content -Raw $validationMatrixPath
    $validationState = Get-StateValue -Content $validationContent -Labels @("Overall State")

    if ([string]::IsNullOrWhiteSpace($validationState)) {
        Add-ValidationItem -Bucket $errors -Message "Could not resolve Overall State from the validation matrix."
    }
    elseif ($validationState -in @("needs-first-build", "blocked", "not-recorded-yet")) {
        Add-ValidationItem -Bucket $errors -Message "Validation matrix state is not publishable: $validationState"
    }
    elseif ($validationState -eq "attention" -and -not $AllowAttentionState.IsPresent) {
        Add-ValidationItem -Bucket $errors -Message "Validation matrix state is attention. Re-run with -AllowAttentionState only if this release intentionally carries known attention items."
    }
    else {
        Add-ValidationItem -Bucket $notes -Message "Validation matrix state is acceptable for release gating: $validationState"
    }
}

if (-not [string]::IsNullOrWhiteSpace($auditPath)) {
    $auditContent = Get-Content -Raw $auditPath
    $auditState = Get-StateValue -Content $auditContent -Labels @("Audit State", "Overall State")

    if ($auditState -eq "failed") {
        Add-ValidationItem -Bucket $errors -Message "Session audit reports a failed state."
    }
}

if (-not [string]::IsNullOrWhiteSpace($cycleChainAuditPath)) {
    $cycleChainContent = Get-Content -Raw $cycleChainAuditPath
    $cycleChainState = Get-StateValue -Content $cycleChainContent -Labels @("Overall Status", "Overall State")
    $cycleChainRunLabel = Get-MetadataValue -Content $cycleChainContent -Label "Run Label"

    if ($cycleChainState -eq "fail") {
        Add-ValidationItem -Bucket $errors -Message "Cycle chain audit reports a failed state."
    }
    elseif ($cycleChainState -eq "warning") {
        Add-ValidationItem -Bucket $warnings -Message "Cycle chain audit reports warnings. Review the evidence chain before publishing."
    }
    elseif (-not [string]::IsNullOrWhiteSpace($cycleChainState)) {
        Add-ValidationItem -Bucket $notes -Message "Cycle chain audit state is acceptable for release gating: $cycleChainState"
    }

    if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
        -not [string]::IsNullOrWhiteSpace($cycleChainRunLabel) -and
        $cycleChainRunLabel -ne $runLabel) {
        Add-ValidationItem -Bucket $errors -Message "Cycle chain audit Run Label does not match the release manifest Run Label."
    }
}

$releaseDir = Split-Path -Parent $resolvedManifestPath
$validationReportPath = Join-Path $releaseDir "release-validation.md"
$resultState = if ($errors.Count -gt 0) { "failed" } else { "passed" }
$warningSection = if ($warnings.Count -gt 0) { ($warnings | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" }
$noteSection = if ($notes.Count -gt 0) { ($notes | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" }
$errorSection = if ($errors.Count -gt 0) { ($errors | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" }

$report = @"
# Lumina-OS Release Validation Report

- Validated At: $(Get-Date -Format s)
- Result: $resultState
- Version: $(if ([string]::IsNullOrWhiteSpace($version)) { "not-recorded-yet" } else { $version })
- Mode: $(if ([string]::IsNullOrWhiteSpace($mode)) { "not-recorded-yet" } else { $mode })
- Run Label: $(if ([string]::IsNullOrWhiteSpace($runLabel)) { "not-recorded-yet" } else { $runLabel })
- Release Manifest: $resolvedManifestPath
- ISO Path: $(if ([string]::IsNullOrWhiteSpace($isoPath)) { "not-recorded-yet" } else { $isoPath })
- Install Report: $(if ([string]::IsNullOrWhiteSpace($installReportPath)) { "not-recorded-yet" } else { $installReportPath })
- Install Report Status: $(if ([string]::IsNullOrWhiteSpace($installReportState)) { "not-recorded-yet" } else { $installReportState })
- Install Report Run Label: $(if ([string]::IsNullOrWhiteSpace($installReportRunLabel)) { "not-recorded-yet" } else { $installReportRunLabel })
- Install Report Selection: $(if ([string]::IsNullOrWhiteSpace($installReportSelection)) { "not-recorded-yet" } else { $installReportSelection })
- Hardware Report: $(if ([string]::IsNullOrWhiteSpace($hardwareReportPath)) { "not-recorded-yet" } else { $hardwareReportPath })
- Hardware Report Status: $(if ([string]::IsNullOrWhiteSpace($hardwareReportState)) { "not-recorded-yet" } else { $hardwareReportState })
- Hardware Report Run Label: $(if ([string]::IsNullOrWhiteSpace($hardwareReportRunLabel)) { "not-recorded-yet" } else { $hardwareReportRunLabel })
- Hardware Report Selection: $(if ([string]::IsNullOrWhiteSpace($hardwareReportSelection)) { "not-recorded-yet" } else { $hardwareReportSelection })
- Exact Evidence Required: $($RequireExactEvidenceRunLabel.IsPresent)
- Readiness State: $(if ([string]::IsNullOrWhiteSpace($readinessState)) { "not-recorded-yet" } else { $readinessState })
- Validation Matrix State: $(if ([string]::IsNullOrWhiteSpace($validationState)) { "not-recorded-yet" } else { $validationState })
- Blocker State: $(if ([string]::IsNullOrWhiteSpace($blockerState)) { "not-recorded-yet" } else { $blockerState })

## Notes
$noteSection

## Warnings
$warningSection

## Errors
$errorSection
"@

Set-Content -Path $validationReportPath -Value $report -Encoding UTF8

if ($errors.Count -gt 0) {
    throw "Release package validation failed. See: $validationReportPath"
}

if ($OutputPathOnly) {
    Write-Output $validationReportPath
}
else {
    Write-Host "Validated Lumina-OS release package:"
    Write-Host "Report: $validationReportPath"
}
