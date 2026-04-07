param(
    [Parameter(Mandatory = $true)]
    [string]$EvidenceSessionPath,
    [string]$ReleaseVersion = "",
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

$syncPackScript = Join-Path $PSScriptRoot "sync-release-evidence-pack.ps1"
$syncSessionStatusScript = Join-Path $PSScriptRoot "sync-release-evidence-session-status.ps1"
$syncControlCenterScript = Join-Path $PSScriptRoot "sync-release-control-center.ps1"

foreach ($requiredScript in @($syncPackScript, $syncSessionStatusScript, $syncControlCenterScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

if (-not (Test-Path $EvidenceSessionPath)) {
    throw "Evidence session not found: $EvidenceSessionPath"
}

$resolvedEvidenceSessionPath = (Resolve-Path $EvidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$createdAt = Get-RecordedValue -Content $sessionContent -Label "Created At"
$evidencePackPath = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack" -DefaultValue ""
if ([string]::IsNullOrWhiteSpace($evidencePackPath) -or $evidencePackPath -eq "not-recorded-yet" -or -not (Test-Path $evidencePackPath)) {
    throw "Evidence session does not point to a valid evidence pack: $resolvedEvidenceSessionPath"
}

$resolvedEvidencePackPath = & $syncPackScript `
    -EvidencePackPath $evidencePackPath `
    -ReleaseVersion $ReleaseVersion `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$resolvedEvidencePackPath = (Resolve-Path $resolvedEvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath

$runLabelValue = Get-RecordedValue -Content $packContent -Label "Run Label"
$modeValue = Get-RecordedValue -Content $packContent -Label "Primary Mode" -DefaultValue "stable"
$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Get-RecordedValue -Content $packContent -Label "Release Version"
}
else {
    $ReleaseVersion.Trim()
}
$evidencePackState = Get-RecordedValue -Content $packContent -Label "Evidence Pack State"
$evidenceReadyCount = Get-RecordedValue -Content $packContent -Label "Evidence Ready Count"
$evidenceChecklistProgress = Get-RecordedValue -Content $packContent -Label "Evidence Checklist Progress"
$runbookPath = Get-RecordedValue -Content $packContent -Label "Runbook Path"
$loginTestReportPath = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$loginTestStatus = Get-RecordedValue -Content $packContent -Label "Login-Test Status"
$loginTestRunLabel = Get-RecordedValue -Content $packContent -Label "Login-Test Run Label"
$loginTestTester = Get-RecordedValue -Content $packContent -Label "Login-Test Tester"
$loginTestProgressState = Get-RecordedValue -Content $packContent -Label "Login-Test Progress State"
$loginTestChecklistProgress = Get-RecordedValue -Content $packContent -Label "Login-Test Checklist Progress"
$loginTestOpenItems = Get-RecordedValue -Content $packContent -Label "Login-Test Open Items"
$installReportPath = Get-RecordedValue -Content $packContent -Label "Install Report"
$installStatus = Get-RecordedValue -Content $packContent -Label "Install Status"
$installRunLabel = Get-RecordedValue -Content $packContent -Label "Install Run Label"
$installTester = Get-RecordedValue -Content $packContent -Label "Install Tester"
$installProgressState = Get-RecordedValue -Content $packContent -Label "Install Progress State"
$installChecklistProgress = Get-RecordedValue -Content $packContent -Label "Install Checklist Progress"
$installOpenItems = Get-RecordedValue -Content $packContent -Label "Install Open Items"
$hardwareReportPath = Get-RecordedValue -Content $packContent -Label "Hardware Report"
$hardwareStatus = Get-RecordedValue -Content $packContent -Label "Hardware Status"
$hardwareRunLabel = Get-RecordedValue -Content $packContent -Label "Hardware Run Label"
$hardwareTester = Get-RecordedValue -Content $packContent -Label "Hardware Tester"
$hardwareProgressState = Get-RecordedValue -Content $packContent -Label "Hardware Progress State"
$hardwareChecklistProgress = Get-RecordedValue -Content $packContent -Label "Hardware Checklist Progress"
$hardwareOpenItems = Get-RecordedValue -Content $packContent -Label "Hardware Open Items"

$null = & $syncControlCenterScript `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$currentEvidencePackSummaryPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-PACK.md"
$currentReleaseControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"

$sessionState = switch ($evidencePackState) {
    "ready-for-rc-gating" { "ready-for-rc-gating" }
    "run-label-mismatch" { "run-label-mismatch" }
    "missing-evidence" { "missing-evidence" }
    "incomplete" { "evidence-in-progress" }
    default { "ready-to-collect-evidence" }
}

$nextEvidenceTarget = "not-recorded-yet"
$nextEvidenceReportPath = "not-recorded-yet"
$nextEvidenceTester = "not-recorded-yet"
$nextEvidenceProgress = "not-recorded-yet"
if (-not (Test-PassState -Value $loginTestStatus)) {
    $nextEvidenceTarget = "login-test"
    $nextEvidenceReportPath = $loginTestReportPath
    $nextEvidenceTester = $loginTestTester
    $nextEvidenceProgress = $loginTestChecklistProgress
}
elseif (-not (Test-PassState -Value $installStatus)) {
    $nextEvidenceTarget = "install"
    $nextEvidenceReportPath = $installReportPath
    $nextEvidenceTester = $installTester
    $nextEvidenceProgress = $installChecklistProgress
}
elseif (-not (Test-PassState -Value $hardwareStatus)) {
    $nextEvidenceTarget = "hardware"
    $nextEvidenceReportPath = $hardwareReportPath
    $nextEvidenceTester = $hardwareTester
    $nextEvidenceProgress = $hardwareChecklistProgress
}
elseif ($evidencePackState -eq "ready-for-rc-gating") {
    $nextEvidenceTarget = "rc-gating"
    $nextEvidenceReportPath = $runbookPath
    $nextEvidenceTester = "n/a"
    $nextEvidenceProgress = $evidenceChecklistProgress
}

$content = @"
# Lumina-OS Release Evidence Session

- Created At: $createdAt
- Synced At: $(Get-Date -Format s)
- Session State: $sessionState
- Run Label: $runLabelValue
- Release Version: $releaseVersionValue
- Mode: $modeValue
- Evidence Pack: $resolvedEvidencePackPath
- Evidence Pack State: $evidencePackState
- Evidence Ready Count: $evidenceReadyCount
- Evidence Checklist Progress: $evidenceChecklistProgress
- Runbook Path: $runbookPath
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $loginTestStatus
- Login-Test Run Label: $loginTestRunLabel
- Login-Test Tester: $loginTestTester
- Login-Test Progress State: $loginTestProgressState
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Login-Test Open Items: $loginTestOpenItems
- Install Report: $installReportPath
- Install Status: $installStatus
- Install Run Label: $installRunLabel
- Install Tester: $installTester
- Install Progress State: $installProgressState
- Install Checklist Progress: $installChecklistProgress
- Install Open Items: $installOpenItems
- Hardware Report: $hardwareReportPath
- Hardware Status: $hardwareStatus
- Hardware Run Label: $hardwareRunLabel
- Hardware Tester: $hardwareTester
- Hardware Progress State: $hardwareProgressState
- Hardware Checklist Progress: $hardwareChecklistProgress
- Hardware Open Items: $hardwareOpenItems
- Next Evidence Target: $nextEvidenceTarget
- Next Evidence Report: $nextEvidenceReportPath
- Next Evidence Tester: $nextEvidenceTester
- Next Evidence Progress: $nextEvidenceProgress
- Current Evidence Pack Summary: $(if (Test-Path $currentEvidencePackSummaryPath) { $currentEvidencePackSummaryPath } else { "not-recorded-yet" })
- Current Release Control Center: $(if (Test-Path $currentReleaseControlCenterPath) { $currentReleaseControlCenterPath } else { "not-recorded-yet" })

## Practical Order
1. Update the login-test report at: $loginTestReportPath
2. Update the install report at: $installReportPath
3. Update the hardware report at: $hardwareReportPath
4. Refresh this evidence session after report updates with:
   .\scripts\sync-release-evidence-session.ps1 -EvidenceSessionPath "$resolvedEvidenceSessionPath" -ReleaseVersion "$releaseVersionValue"
5. Review status/evidence-packs/CURRENT-EVIDENCE-SESSION.md and status/evidence-packs/CURRENT-EVIDENCE-PACK.md.
6. Run the evidence and readiness audits from the generated runbook:
   $runbookPath

## Goal
- keep the real validation session on one shared Run Label
- move from scaffolding into real login-test, install, and hardware evidence capture
- keep evidence progress visible from the pack, session, execution, and shareable summaries
"@

Set-Content -Path $resolvedEvidenceSessionPath -Value $content -Encoding UTF8

$null = & $syncSessionStatusScript `
    -EvidenceSessionPath $resolvedEvidenceSessionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $resolvedEvidenceSessionPath
}
else {
    Write-Host "Synced release evidence session:"
    Write-Host $resolvedEvidenceSessionPath
}
