param(
    [string]$ExecutionPath = "",
    [switch]$Open,
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

function Get-ContentIfExists {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and $Path -ne "not-recorded-yet" -and (Test-Path $Path)) {
        return Get-Content -Raw $Path
    }

    return ""
}

function Get-ActionPackDirectory {
    param([string]$ActionPackPath)

    if ([string]::IsNullOrWhiteSpace($ActionPackPath) -or $ActionPackPath -eq "not-recorded-yet" -or -not (Test-Path $ActionPackPath)) {
        return ""
    }

    $item = Get-Item -LiteralPath $ActionPackPath
    if ($item.PSIsContainer) {
        return $item.FullName
    }

    return $item.DirectoryName
}

function Get-ActionPackHelperPath {
    param(
        [string]$ActionPackPath,
        [string]$HelperName
    )

    $actionPackDir = Get-ActionPackDirectory -ActionPackPath $ActionPackPath
    if ([string]::IsNullOrWhiteSpace($actionPackDir)) {
        return ""
    }

    $helperPath = Join-Path $actionPackDir $HelperName
    if (Test-Path $helperPath) {
        return (Resolve-Path $helperPath).Path
    }

    return ""
}

function Resolve-ExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and $candidate -ne "not-recorded-yet" -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    return ""
}

function Invoke-ResolvedAction {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Cannot invoke an empty next action path."
    }

    $resolvedPath = (Resolve-Path $Path).Path
    if ($resolvedPath.ToLowerInvariant().EndsWith(".ps1")) {
        & $resolvedPath
        return
    }

    Invoke-Item -LiteralPath $resolvedPath
}

$resolvedExecutionPath = if ([string]::IsNullOrWhiteSpace($ExecutionPath)) {
    Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-EXECUTION.md"
}
else {
    $ExecutionPath
}

if (-not (Test-Path $resolvedExecutionPath)) {
    throw "Release execution path not found: $resolvedExecutionPath"
}

$resolvedExecutionPath = (Resolve-Path $resolvedExecutionPath).Path
$executionContent = Get-Content -Raw $resolvedExecutionPath

$executionState = Get-RecordedValue -Content $executionContent -Label "Execution State"
$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$actionPackPath = Get-RecordedValue -Content $executionContent -Label "Action Pack Path"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$currentControlCenterPath = Get-RecordedValue -Content $executionContent -Label "Current Release Control Center"

if ($currentControlCenterPath -eq "not-recorded-yet") {
    $currentControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"
}

if ($evidenceSessionPath -eq "not-recorded-yet") {
    $evidenceSessionPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"
}

$controlCenterContent = Get-ContentIfExists -Path $currentControlCenterPath
$evidenceSessionContent = Get-ContentIfExists -Path $evidenceSessionPath

$controlState = Get-RecordedValue -Content $controlCenterContent -Label "Release Control State" -DefaultValue ""
$nextEvidenceTarget = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Target" -DefaultValue ""
$nextEvidenceReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Report" -DefaultValue ""
$currentReleaseCandidatePath = Get-RecordedValue -Content $controlCenterContent -Label "Current Release Candidate" -DefaultValue ""
$currentReleaseEvidencePath = Get-RecordedValue -Content $controlCenterContent -Label "Current Release Evidence" -DefaultValue ""
$currentReleaseReadinessPath = Get-RecordedValue -Content $controlCenterContent -Label "Current Release Readiness" -DefaultValue ""

$resolvedActionLabel = ""
$resolvedActionPath = ""

$nextEvidenceHelperPath = Get-ActionPackHelperPath -ActionPackPath $actionPackPath -HelperName "20-open-next-evidence.ps1"
$evidenceAuditHelperPath = Get-ActionPackHelperPath -ActionPackPath $actionPackPath -HelperName "50-audit-release-evidence.ps1"
$prepareCandidateHelperPath = Get-ActionPackHelperPath -ActionPackPath $actionPackPath -HelperName "60-prepare-release-candidate.ps1"
$readinessAuditHelperPath = Get-ActionPackHelperPath -ActionPackPath $actionPackPath -HelperName "70-audit-release-readiness.ps1"

switch ($controlState) {
    "ready-for-evidence-audit" {
        $resolvedActionLabel = "evidence-audit"
        $resolvedActionPath = Resolve-ExistingPath @($evidenceAuditHelperPath, $currentReleaseEvidencePath, $actionPackPath, $currentControlCenterPath)
    }
    "ready-for-strict-rc" {
        $resolvedActionLabel = "prepare-release-candidate"
        $resolvedActionPath = Resolve-ExistingPath @($prepareCandidateHelperPath, $currentReleaseCandidatePath, $actionPackPath, $currentControlCenterPath)
    }
    "ready-for-readiness-audit" {
        $resolvedActionLabel = "prepare-release-candidate"
        $resolvedActionPath = Resolve-ExistingPath @($prepareCandidateHelperPath, $currentReleaseCandidatePath, $actionPackPath, $currentControlCenterPath)
    }
    "candidate-sync-needed" {
        $resolvedActionLabel = "prepare-release-candidate"
        $resolvedActionPath = Resolve-ExistingPath @($prepareCandidateHelperPath, $currentReleaseCandidatePath, $currentControlCenterPath)
    }
    "ready-to-publish" {
        $resolvedActionLabel = "release-candidate-summary"
        $resolvedActionPath = Resolve-ExistingPath @($currentReleaseCandidatePath, $readinessAuditHelperPath, $currentReleaseReadinessPath, $currentControlCenterPath)
    }
    "published" {
        $resolvedActionLabel = "release-candidate-summary"
        $resolvedActionPath = Resolve-ExistingPath @($currentReleaseCandidatePath, $currentControlCenterPath, $resolvedExecutionPath)
    }
}

if ([string]::IsNullOrWhiteSpace($resolvedActionPath)) {
    switch ($executionState) {
        "ready-to-execute" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath)
        }
        "awaiting-login-test-evidence" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath)
        }
        "awaiting-install-evidence" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath)
        }
        "awaiting-hardware-evidence" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath)
        }
        "evidence-in-progress" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath)
        }
        "evidence-run-label-mismatch" {
            $resolvedActionLabel = "next-evidence"
            $resolvedActionPath = Resolve-ExistingPath @($nextEvidenceHelperPath, $nextEvidenceReportPath, $evidenceSessionPath, $currentControlCenterPath)
        }
        "ready-for-rc-gating" {
            $resolvedActionLabel = "evidence-audit"
            $resolvedActionPath = Resolve-ExistingPath @($evidenceAuditHelperPath, $currentReleaseEvidencePath, $actionPackPath, $currentControlCenterPath)
        }
    }
}

if ([string]::IsNullOrWhiteSpace($resolvedActionPath)) {
    $resolvedActionLabel = "release-control-center"
    $resolvedActionPath = Resolve-ExistingPath @($currentControlCenterPath, $evidenceSessionPath, $resolvedExecutionPath)
}

if ([string]::IsNullOrWhiteSpace($resolvedActionPath)) {
    throw "Could not resolve the next release action from: $resolvedExecutionPath"
}

if ($OutputPathOnly) {
    Write-Output $resolvedActionPath
    return
}

Write-Host "Resolved next release action:"
Write-Host "Label:   $resolvedActionLabel"
Write-Host "Path:    $resolvedActionPath"
Write-Host "State:   $executionState / $controlState"
Write-Host "RunLabel:$runLabel"
Write-Host "Target:  $nextEvidenceTarget"
Write-Host "Session: $evidenceSessionPath"

if ($Open) {
    Invoke-ResolvedAction -Path $resolvedActionPath
}
