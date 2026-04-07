param(
    [string]$EvidenceSessionPath = "",
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

function Test-PassState {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "not-recorded-yet") {
        return $false
    }

    $normalized = $Value.Trim().ToLowerInvariant()
    return @(
        "pass",
        "passed",
        "complete",
        "completed",
        "success",
        "successful",
        "ready-for-release",
        "ready-for-real-device-smoke"
    ) -contains $normalized
}

$resolvedEvidenceSessionPath = if ([string]::IsNullOrWhiteSpace($EvidenceSessionPath)) {
    Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"
}
else {
    $EvidenceSessionPath
}

if (-not (Test-Path $resolvedEvidenceSessionPath)) {
    throw "Evidence session not found: $resolvedEvidenceSessionPath"
}

$resolvedEvidenceSessionPath = (Resolve-Path $resolvedEvidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$sessionState = Get-RecordedValue -Content $sessionContent -Label "Session State"
$runLabel = Get-RecordedValue -Content $sessionContent -Label "Run Label"
$nextEvidenceTarget = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Target"
$nextEvidenceReportPath = Get-RecordedValue -Content $sessionContent -Label "Next Evidence Report"
$runbookPath = Get-RecordedValue -Content $sessionContent -Label "Runbook Path"
$loginTestReportPath = Get-RecordedValue -Content $sessionContent -Label "Login-Test Report"
$loginTestStatus = Get-RecordedValue -Content $sessionContent -Label "Login-Test Status"
$installReportPath = Get-RecordedValue -Content $sessionContent -Label "Install Report"
$installStatus = Get-RecordedValue -Content $sessionContent -Label "Install Status"
$hardwareReportPath = Get-RecordedValue -Content $sessionContent -Label "Hardware Report"
$hardwareStatus = Get-RecordedValue -Content $sessionContent -Label "Hardware Status"

if ($nextEvidenceTarget -eq "not-recorded-yet" -or $nextEvidenceReportPath -eq "not-recorded-yet") {
    if (-not (Test-PassState -Value $loginTestStatus)) {
        $nextEvidenceTarget = "login-test"
        $nextEvidenceReportPath = $loginTestReportPath
    }
    elseif (-not (Test-PassState -Value $installStatus)) {
        $nextEvidenceTarget = "install"
        $nextEvidenceReportPath = $installReportPath
    }
    elseif (-not (Test-PassState -Value $hardwareStatus)) {
        $nextEvidenceTarget = "hardware"
        $nextEvidenceReportPath = $hardwareReportPath
    }
    elseif ($sessionState -eq "ready-for-rc-gating" -and $runbookPath -ne "not-recorded-yet") {
        $nextEvidenceTarget = "rc-gating"
        $nextEvidenceReportPath = $runbookPath
    }
}

if ([string]::IsNullOrWhiteSpace($nextEvidenceReportPath) -or $nextEvidenceReportPath -eq "not-recorded-yet") {
    throw "Could not resolve the next evidence report from: $resolvedEvidenceSessionPath"
}

if (-not (Test-Path $nextEvidenceReportPath)) {
    throw "Next evidence path does not exist: $nextEvidenceReportPath"
}

$resolvedNextEvidencePath = (Resolve-Path $nextEvidenceReportPath).Path

if ($OutputPathOnly) {
    Write-Output $resolvedNextEvidencePath
    return
}

Write-Host "Resolved next release evidence target:"
Write-Host "Target:  $nextEvidenceTarget"
Write-Host "Path:    $resolvedNextEvidencePath"
Write-Host "RunLabel:$runLabel"
Write-Host "Session: $resolvedEvidenceSessionPath"

if ($Open) {
    Invoke-Item -LiteralPath $resolvedNextEvidencePath
}
