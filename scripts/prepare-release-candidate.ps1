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

$prepareScript = Join-Path $PSScriptRoot "prepare-release-package.ps1"
$validateScript = Join-Path $PSScriptRoot "validate-release-package.ps1"
$syncScript = Join-Path $PSScriptRoot "sync-release-candidate-status.ps1"

if (-not (Test-Path $prepareScript)) {
    throw "Missing helper: $prepareScript"
}

if (-not (Test-Path $validateScript)) {
    throw "Missing helper: $validateScript"
}

if (-not (Test-Path $syncScript)) {
    throw "Missing helper: $syncScript"
}

$prepareArgs = @{
    Version = $Version
    Mode = $Mode
    IsoPath = $IsoPath
    RunLabel = $RunLabel
    BuildManifestPath = $BuildManifestPath
    VmReportPath = $VmReportPath
    LoginTestReportPath = $LoginTestReportPath
    InstallReportPath = $InstallReportPath
    HardwareReportPath = $HardwareReportPath
    SessionPath = $SessionPath
    AuditPath = $AuditPath
    CycleChainAuditPath = $CycleChainAuditPath
    ReadinessPath = $ReadinessPath
    ValidationMatrixPath = $ValidationMatrixPath
    RepoRoot = $RepoRoot
    OutputPathOnly = $true
}

$manifestPath = & $prepareScript @prepareArgs
if (-not $manifestPath -or -not (Test-Path $manifestPath)) {
    throw "Unable to prepare the release package manifest."
}

$validationArgs = @{
    ReleaseManifestPath = $manifestPath
    RepoRoot = $RepoRoot
    OutputPathOnly = $true
}

if ($AllowAttentionState.IsPresent) {
    $validationArgs["AllowAttentionState"] = $true
}

if ($RequireExactEvidenceRunLabel.IsPresent) {
    $validationArgs["RequireExactEvidenceRunLabel"] = $true
}

$validationReportPath = Join-Path (Split-Path -Parent $manifestPath) "release-validation.md"
$validationError = ""

try {
    $resolvedValidationReportPath = & $validateScript @validationArgs
    if ($resolvedValidationReportPath) {
        $validationReportPath = $resolvedValidationReportPath
    }
}
catch {
    $validationError = $_.Exception.Message
}

$syncArgs = @{
    ReleaseManifestPath = $manifestPath
    ValidationReportPath = $validationReportPath
    RepoRoot = $RepoRoot
    OutputPathOnly = $true
}

$candidateSummaryPath = & $syncScript @syncArgs
if (-not $candidateSummaryPath -or -not (Test-Path $candidateSummaryPath)) {
    throw "Unable to sync the release candidate summary."
}

if (-not [string]::IsNullOrWhiteSpace($validationError)) {
    throw "Release candidate validation failed. Summary: $candidateSummaryPath | Validation Report: $validationReportPath"
}

if ($OutputPathOnly) {
    Write-Output $candidateSummaryPath
}
else {
    Write-Host "Prepared Lumina-OS release candidate:"
    Write-Host "Summary:           $candidateSummaryPath"
    Write-Host "Release Manifest:  $manifestPath"
    Write-Host "Validation Report: $validationReportPath"
}
