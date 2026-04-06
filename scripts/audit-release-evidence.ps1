param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "stable",
    [string]$RunLabel = "",
    [string]$IsoPath = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$EvidencePackPath = "",
    [string]$LoginTestReportPath = "",
    [string]$InstallReportPath = "",
    [string]$HardwareReportPath = "",
    [string]$SessionPath = "",
    [string]$AuditPath = "",
    [string]$CycleChainAuditPath = "",
    [string]$ReadinessPath = "",
    [string]$ValidationMatrixPath = "",
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

function Invoke-ReleaseValidationPass {
    param(
        [string]$ValidatorPath,
        [string]$ManifestPath,
        [string]$ReleaseDir,
        [string]$RepoRoot,
        [switch]$AllowAttentionState,
        [switch]$RequireExactEvidenceRunLabel
    )

    $validationArgs = @{
        ReleaseManifestPath = $ManifestPath
        RepoRoot = $RepoRoot
        OutputPathOnly = $true
    }

    if ($AllowAttentionState.IsPresent) {
        $validationArgs["AllowAttentionState"] = $true
    }

    if ($RequireExactEvidenceRunLabel.IsPresent) {
        $validationArgs["RequireExactEvidenceRunLabel"] = $true
    }

    $reportPath = Join-Path $ReleaseDir "release-validation.md"
    $errorMessage = ""

    try {
        $resolvedReportPath = & $ValidatorPath @validationArgs
        if ($resolvedReportPath) {
            $reportPath = $resolvedReportPath
        }
        $state = "passed"
    }
    catch {
        $errorMessage = $_.Exception.Message
        $state = "failed"
    }

    $resolvedPath = if (Test-Path $reportPath) { (Resolve-Path $reportPath).Path } else { "" }
    $content = if (-not [string]::IsNullOrWhiteSpace($resolvedPath)) { Get-Content -Raw $resolvedPath } else { "" }
    $resultValue = Get-MetadataValue -Content $content -Label "Result"

    return @{
        State = $state
        ReportPath = $resolvedPath
        ErrorMessage = $errorMessage
        Content = $content
        ResultValue = $resultValue
    }
}

$prepareScript = Join-Path $PSScriptRoot "prepare-release-package.ps1"
$validateScript = Join-Path $PSScriptRoot "validate-release-package.ps1"

if (-not (Test-Path $prepareScript)) {
    throw "Missing helper: $prepareScript"
}

if (-not (Test-Path $validateScript)) {
    throw "Missing helper: $validateScript"
}

$prepareArgs = @{
    Version = $Version
    Mode = $Mode
    RunLabel = $RunLabel
    IsoPath = $IsoPath
    BuildManifestPath = $BuildManifestPath
    VmReportPath = $VmReportPath
    EvidencePackPath = $EvidencePackPath
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
    throw "Unable to prepare a release package manifest for audit."
}

$resolvedManifestPath = (Resolve-Path $manifestPath).Path
$releaseDir = Split-Path -Parent $resolvedManifestPath
$auditReportPath = Join-Path $releaseDir "release-evidence-audit.md"
$strictReportPath = Join-Path $releaseDir "release-validation-strict.md"

$softValidation = Invoke-ReleaseValidationPass `
    -ValidatorPath $validateScript `
    -ManifestPath $resolvedManifestPath `
    -ReleaseDir $releaseDir `
    -RepoRoot $RepoRoot `
    -AllowAttentionState:$AllowAttentionState.IsPresent

$softReportContent = $softValidation.Content

$strictValidation = Invoke-ReleaseValidationPass `
    -ValidatorPath $validateScript `
    -ManifestPath $resolvedManifestPath `
    -ReleaseDir $releaseDir `
    -RepoRoot $RepoRoot `
    -AllowAttentionState:$AllowAttentionState.IsPresent `
    -RequireExactEvidenceRunLabel

if (-not [string]::IsNullOrWhiteSpace($strictValidation.ReportPath) -and (Test-Path $strictValidation.ReportPath)) {
    Copy-Item -Path $strictValidation.ReportPath -Destination $strictReportPath -Force
}

if (-not [string]::IsNullOrWhiteSpace($softReportContent)) {
    Set-Content -Path (Join-Path $releaseDir "release-validation.md") -Value $softReportContent -Encoding UTF8
}

$manifestContent = Get-Content -Raw $resolvedManifestPath
$summaryItems = [System.Collections.Generic.List[string]]::new()

$runLabelValue = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$isoPathValue = Get-MetadataValue -Content $manifestContent -Label "ISO Path"
$evidencePackValue = Get-MetadataValue -Content $manifestContent -Label "Evidence Pack"
$loginTestReportValue = Get-MetadataValue -Content $manifestContent -Label "Login-Test Report"
$loginTestRunLabelValue = Get-MetadataValue -Content $manifestContent -Label "Login-Test Report Run Label"
$loginTestSelectionValue = Get-MetadataValue -Content $manifestContent -Label "Login-Test Report Selection"
$installReportValue = Get-MetadataValue -Content $manifestContent -Label "Install Report"
$installRunLabelValue = Get-MetadataValue -Content $manifestContent -Label "Install Report Run Label"
$installSelectionValue = Get-MetadataValue -Content $manifestContent -Label "Install Report Selection"
$hardwareReportValue = Get-MetadataValue -Content $manifestContent -Label "Hardware Report"
$hardwareRunLabelValue = Get-MetadataValue -Content $manifestContent -Label "Hardware Report Run Label"
$hardwareSelectionValue = Get-MetadataValue -Content $manifestContent -Label "Hardware Report Selection"

if ($softValidation.State -eq "passed" -and $strictValidation.State -eq "passed") {
    $summaryItems.Add("Soft and strict release evidence gates both pass.") | Out-Null
}
elseif ($softValidation.State -eq "passed") {
    $summaryItems.Add("Soft evidence gate passes, but strict evidence gate still needs exact run-label evidence.") | Out-Null
}
else {
    $summaryItems.Add("Soft evidence gate does not pass yet; release evidence is not ready.") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($installSelectionValue)) {
    $summaryItems.Add("Install evidence selection: $installSelectionValue") | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($hardwareSelectionValue)) {
    $summaryItems.Add("Hardware evidence selection: $hardwareSelectionValue") | Out-Null
}

$recommendationItems = [System.Collections.Generic.List[string]]::new()
if ($softValidation.State -ne "passed") {
    $recommendationItems.Add("Complete missing install, hardware, or release evidence gates before preparing the final release candidate.") | Out-Null
}
elseif ($strictValidation.State -ne "passed") {
    $recommendationItems.Add("For a strict release gate, provide exact install and hardware evidence for the same run label or pass explicit report paths.") | Out-Null
}
else {
    $recommendationItems.Add("This evidence set is ready for a strict release-candidate pass when you decide to run it.") | Out-Null
}

$reportContent = @"
# Lumina-OS Release Evidence Audit

- Audited At: $(Get-Date -Format s)
- Version: $Version
- Mode: $Mode
- Run Label: $(Get-ResolvedPathOrDefault -Value $runLabelValue -DefaultValue "not-recorded-yet")
- Release Manifest: $resolvedManifestPath
- Soft Validation Report: $(Get-ResolvedPathOrDefault -Value $softValidation.ReportPath -DefaultValue "not-recorded-yet")
- Soft Gate State: $($softValidation.State)
- Soft Gate Result: $(Get-ResolvedPathOrDefault -Value $softValidation.ResultValue -DefaultValue "not-recorded-yet")
- Strict Validation Report: $(if (Test-Path $strictReportPath) { $strictReportPath } else { "not-recorded-yet" })
- Strict Gate State: $($strictValidation.State)
- Strict Gate Result: $(Get-ResolvedPathOrDefault -Value $strictValidation.ResultValue -DefaultValue "not-recorded-yet")

## Evidence Links
- ISO Path: $(Get-ResolvedPathOrDefault -Value $isoPathValue -DefaultValue "not-recorded-yet")
- Evidence Pack: $(Get-ResolvedPathOrDefault -Value $evidencePackValue -DefaultValue "not-recorded-yet")
- Login-Test Report: $(Get-ResolvedPathOrDefault -Value $loginTestReportValue -DefaultValue "not-recorded-yet")
- Login-Test Report Run Label: $(Get-ResolvedPathOrDefault -Value $loginTestRunLabelValue -DefaultValue "not-recorded-yet")
- Login-Test Report Selection: $(Get-ResolvedPathOrDefault -Value $loginTestSelectionValue -DefaultValue "not-recorded-yet")
- Install Report: $(Get-ResolvedPathOrDefault -Value $installReportValue -DefaultValue "not-recorded-yet")
- Install Report Run Label: $(Get-ResolvedPathOrDefault -Value $installRunLabelValue -DefaultValue "not-recorded-yet")
- Install Report Selection: $(Get-ResolvedPathOrDefault -Value $installSelectionValue -DefaultValue "not-recorded-yet")
- Hardware Report: $(Get-ResolvedPathOrDefault -Value $hardwareReportValue -DefaultValue "not-recorded-yet")
- Hardware Report Run Label: $(Get-ResolvedPathOrDefault -Value $hardwareRunLabelValue -DefaultValue "not-recorded-yet")
- Hardware Report Selection: $(Get-ResolvedPathOrDefault -Value $hardwareSelectionValue -DefaultValue "not-recorded-yet")

## Summary
$(Format-Items -Items $summaryItems)

## Soft Gate Error
$(if ([string]::IsNullOrWhiteSpace($softValidation.ErrorMessage)) { "- none" } else { "- $($softValidation.ErrorMessage)" })

## Strict Gate Error
$(if ([string]::IsNullOrWhiteSpace($strictValidation.ErrorMessage)) { "- none" } else { "- $($strictValidation.ErrorMessage)" })

## Recommendation
$(Format-Items -Items $recommendationItems)
"@

Set-Content -Path $auditReportPath -Value $reportContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $auditReportPath
}
else {
    Write-Host "Audited Lumina-OS release evidence:"
    Write-Host "Audit Report:           $auditReportPath"
    Write-Host "Soft Gate State:        $($softValidation.State)"
    Write-Host "Strict Gate State:      $($strictValidation.State)"
}
