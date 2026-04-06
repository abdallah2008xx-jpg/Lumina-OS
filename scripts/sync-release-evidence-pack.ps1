param(
    [Parameter(Mandatory = $true)]
    [string]$EvidencePackPath,
    [string]$ReleaseVersion = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

function Get-ReportSnapshot {
    param(
        [string]$Path,
        [string[]]$StatusLabels,
        [string[]]$PassStates
    )

    $result = @{
        Path = $Path
        Exists = $false
        Status = "not-recorded-yet"
        RunLabel = "not-recorded-yet"
        Pass = $false
    }

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq "not-recorded-yet" -or -not (Test-Path $Path)) {
        return $result
    }

    $content = Get-Content -Raw $Path -ErrorAction SilentlyContinue
    $status = Get-StateValue -Content $content -Labels $StatusLabels
    $runLabel = Get-MetadataValue -Content $content -Label "Run Label"
    $normalizedStatus = if ([string]::IsNullOrWhiteSpace($status)) { "" } else { $status.Trim().ToLowerInvariant() }

    $result.Exists = $true
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        $result.Status = $status
    }
    if (-not [string]::IsNullOrWhiteSpace($runLabel)) {
        $result.RunLabel = $runLabel
    }
    if (-not [string]::IsNullOrWhiteSpace($normalizedStatus) -and $PassStates -contains $normalizedStatus) {
        $result.Pass = $true
    }

    return $result
}

if (-not (Test-Path $EvidencePackPath)) {
    throw "Evidence pack path not found: $EvidencePackPath"
}

$runbookScript = Join-Path $PSScriptRoot "new-release-evidence-runbook.ps1"
if (-not (Test-Path $runbookScript)) {
    throw "Missing helper script: $runbookScript"
}

$statusScript = Join-Path $PSScriptRoot "sync-release-evidence-pack-status.ps1"
if (-not (Test-Path $statusScript)) {
    throw "Missing helper script: $statusScript"
}

$resolvedEvidencePackPath = (Resolve-Path $EvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath

$createdAt = Get-RecordedValue -Content $packContent -Label "Created At"
$runLabel = Get-RecordedValue -Content $packContent -Label "Run Label"
$mode = Get-RecordedValue -Content $packContent -Label "Primary Mode" -DefaultValue "stable"
$vmType = Get-RecordedValue -Content $packContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $packContent -Label "Firmware"
$isoPath = Get-RecordedValue -Content $packContent -Label "ISO Path"
$storedReleaseVersion = Get-RecordedValue -Content $packContent -Label "Release Version"
$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) { $storedReleaseVersion } else { $ReleaseVersion.Trim() }
$deviceLabel = Get-RecordedValue -Content $packContent -Label "Device Label"
$bootSource = Get-RecordedValue -Content $packContent -Label "Boot Source"
$loginTestReportPath = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $packContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $packContent -Label "Hardware Report"
$runbookPath = Get-RecordedValue -Content $packContent -Label "Runbook Path"

$loginTestSnapshot = Get-ReportSnapshot -Path $loginTestReportPath -StatusLabels @("Overall Status", "Overall State", "Result") -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-release")
$installSnapshot = Get-ReportSnapshot -Path $installReportPath -StatusLabels @("Overall Status", "Overall State", "Result") -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-release")
$hardwareSnapshot = Get-ReportSnapshot -Path $hardwareReportPath -StatusLabels @("Overall Status", "Hardware Readiness", "Overall State", "Result") -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-real-device-smoke", "ready-for-release")

$allExist = $loginTestSnapshot.Exists -and $installSnapshot.Exists -and $hardwareSnapshot.Exists
$allPass = $loginTestSnapshot.Pass -and $installSnapshot.Pass -and $hardwareSnapshot.Pass
$runLabelMatch = (
    $loginTestSnapshot.RunLabel -eq $runLabel -and
    $installSnapshot.RunLabel -eq $runLabel -and
    $hardwareSnapshot.RunLabel -eq $runLabel
)

$evidencePackState = if (-not $allExist) {
    "missing-evidence"
}
elseif (-not $runLabelMatch) {
    "run-label-mismatch"
}
elseif (-not $allPass) {
    "incomplete"
}
else {
    "ready-for-rc-gating"
}

$content = @"
# Lumina-OS Release Evidence Pack

- Created At: $createdAt
- Synced At: $(Get-Date -Format s)
- Run Label: $runLabel
- Primary Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- ISO Path: $isoPath
- Release Version: $releaseVersionValue
- Device Label: $deviceLabel
- Boot Source: $bootSource
- Evidence Pack State: $evidencePackState
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $($loginTestSnapshot.Status)
- Login-Test Run Label: $($loginTestSnapshot.RunLabel)
- Install Report: $installReportPath
- Install Status: $($installSnapshot.Status)
- Install Run Label: $($installSnapshot.RunLabel)
- Hardware Report: $hardwareReportPath
- Hardware Status: $($hardwareSnapshot.Status)
- Hardware Run Label: $($hardwareSnapshot.RunLabel)
- Runbook Path: $runbookPath

## Purpose
- keep `login-test`, `install`, and `hardware` evidence on the same `Run Label`
- reduce release-prep drift before the final RC gate

## Next Step
- rerun `new-release-evidence-runbook.ps1` or use this pack directly in release evidence audit and RC prep
- if `Evidence Pack State` is not `ready-for-rc-gating`, fix the missing or mismatched evidence before strict release gating
"@

Set-Content -Path $resolvedEvidencePackPath -Value $content -Encoding UTF8

$runbookPath = & $runbookScript `
    -EvidencePackPath $resolvedEvidencePackPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$null = & $statusScript `
    -EvidencePackPath $resolvedEvidencePackPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $resolvedEvidencePackPath
}
else {
    Write-Host "Synced release evidence pack:"
    Write-Host $resolvedEvidencePackPath
}
