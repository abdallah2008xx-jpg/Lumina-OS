param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPath,
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

function Convert-ToPsLiteral {
    param([string]$Value)

    if ($null -eq $Value) {
        return "''"
    }

    return "'" + ($Value -replace "'", "''") + "'"
}

function Write-HelperScript {
    param(
        [string]$Path,
        [string]$Body
    )

    Set-Content -Path $Path -Value $Body -Encoding ASCII
}

if (-not (Test-Path $ExecutionPath)) {
    throw "Execution path not found: $ExecutionPath"
}

$openNextEvidenceScript = Join-Path $PSScriptRoot "open-next-release-evidence.ps1"
if (-not (Test-Path $openNextEvidenceScript)) {
    throw "Missing helper script: $openNextEvidenceScript"
}

$openNextReleaseActionScript = Join-Path $PSScriptRoot "open-next-release-action.ps1"
if (-not (Test-Path $openNextReleaseActionScript)) {
    throw "Missing helper script: $openNextReleaseActionScript"
}

$resolvedExecutionPath = (Resolve-Path $ExecutionPath).Path
$executionContent = Get-Content -Raw $resolvedExecutionPath

$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Get-RecordedValue -Content $executionContent -Label "Release Version" -DefaultValue "0.1.0-dev"
}
else {
    $ReleaseVersion.Trim()
}

$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$mode = Get-RecordedValue -Content $executionContent -Label "Mode" -DefaultValue "stable"
$cycleHandoffPath = Get-RecordedValue -Content $executionContent -Label "Cycle Handoff"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$evidencePackPath = Get-RecordedValue -Content $executionContent -Label "Evidence Pack"
$evidenceRunbookPath = Get-RecordedValue -Content $executionContent -Label "Runbook Path"
$executionRunbookPath = Get-RecordedValue -Content $executionContent -Label "Execution Runbook Path"
$workboardPath = Get-RecordedValue -Content $executionContent -Label "Workboard Path"
$currentControlCenterPath = Get-RecordedValue -Content $executionContent -Label "Current Release Control Center"
$currentEvidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Current Evidence Session"

$evidenceSessionContent = ""
if ($evidenceSessionPath -ne "not-recorded-yet" -and (Test-Path $evidenceSessionPath)) {
    $evidenceSessionContent = Get-Content -Raw $evidenceSessionPath
}

$loginTestReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Report"

$executionLeaf = Split-Path -Leaf $resolvedExecutionPath
if ($executionRunbookPath -eq "not-recorded-yet") {
    $runbookLeaf = if ($executionLeaf -like "release-validation-pass-*.md") {
        $executionLeaf -replace "^release-validation-pass-", "release-validation-runbook-"
    }
    else {
        "release-validation-runbook.md"
    }
    $executionRunbookPath = Join-Path (Split-Path -Parent $resolvedExecutionPath) $runbookLeaf
}

if ($workboardPath -eq "not-recorded-yet") {
    $workboardLeaf = if ($executionLeaf -like "release-validation-pass-*.md") {
        $executionLeaf -replace "^release-validation-pass-", "release-validation-workboard-"
    }
    else {
        "release-validation-workboard.md"
    }
    $workboardPath = Join-Path (Split-Path -Parent $resolvedExecutionPath) $workboardLeaf
}

$safeRunLabel = Get-SafeFileSegment $runLabel
$executionDir = Split-Path -Parent $resolvedExecutionPath
$packDir = Join-Path $executionDir ("release-validation-actions-" + $safeRunLabel)
$packReadmePath = Join-Path $packDir "README.md"

New-Item -ItemType Directory -Force -Path $packDir | Out-Null

$repoRootLiteral = Convert-ToPsLiteral $RepoRoot
$executionPathLiteral = Convert-ToPsLiteral $resolvedExecutionPath
$evidenceSessionPathLiteral = Convert-ToPsLiteral $evidenceSessionPath
$evidencePackPathLiteral = Convert-ToPsLiteral $evidencePackPath
$cycleHandoffPathLiteral = Convert-ToPsLiteral $cycleHandoffPath
$loginTestReportPathLiteral = Convert-ToPsLiteral $loginTestReportPath
$installReportPathLiteral = Convert-ToPsLiteral $installReportPath
$hardwareReportPathLiteral = Convert-ToPsLiteral $hardwareReportPath
$controlCenterPathLiteral = Convert-ToPsLiteral $currentControlCenterPath
$executionRunbookPathLiteral = Convert-ToPsLiteral $executionRunbookPath
$workboardPathLiteral = Convert-ToPsLiteral $workboardPath
$releaseVersionLiteral = Convert-ToPsLiteral $releaseVersionValue
$modeLiteral = Convert-ToPsLiteral $mode
$runLabelLiteral = Convert-ToPsLiteral $runLabel

Write-HelperScript -Path (Join-Path $packDir "00-run-next-step.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\open-next-release-action.ps1') -ExecutionPath $executionPathLiteral -RepoRoot `$repoRoot -Open
"@

Write-HelperScript -Path (Join-Path $packDir "10-open-cycle-handoff.ps1") -Body @"
`$path = $cycleHandoffPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Cycle handoff not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "20-open-next-evidence.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\open-next-release-evidence.ps1') -EvidenceSessionPath $evidenceSessionPathLiteral -RepoRoot `$repoRoot -Open
"@

Write-HelperScript -Path (Join-Path $packDir "21-open-login-test-report.ps1") -Body @"
`$path = $loginTestReportPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Login-test report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "22-open-install-report.ps1") -Body @"
`$path = $installReportPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Install report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "23-open-hardware-report.ps1") -Body @"
`$path = $hardwareReportPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Hardware report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "30-sync-evidence-session.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\sync-release-evidence-session.ps1') -EvidenceSessionPath $evidenceSessionPathLiteral -ReleaseVersion $releaseVersionLiteral -RepoRoot `$repoRoot
"@

Write-HelperScript -Path (Join-Path $packDir "31-sync-release-validation-pass.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\sync-release-validation-pass.ps1') -ExecutionPath $executionPathLiteral -ReleaseVersion $releaseVersionLiteral -RepoRoot `$repoRoot
"@

Write-HelperScript -Path (Join-Path $packDir "40-open-control-center.ps1") -Body @"
`$path = $controlCenterPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Release control center not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "41-open-execution-runbook.ps1") -Body @"
`$path = $executionRunbookPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Execution runbook not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "42-open-workboard.ps1") -Body @"
`$path = $workboardPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Release validation workboard not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "50-audit-release-evidence.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\audit-release-evidence.ps1') -Version $releaseVersionLiteral -Mode $modeLiteral -RunLabel $runLabelLiteral -EvidencePackPath $evidencePackPathLiteral -RepoRoot `$repoRoot
"@

Write-HelperScript -Path (Join-Path $packDir "60-prepare-release-candidate.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\prepare-release-candidate.ps1') -Version $releaseVersionLiteral -Mode $modeLiteral -RunLabel $runLabelLiteral -EvidencePackPath $evidencePackPathLiteral -RepoRoot `$repoRoot
"@

Write-HelperScript -Path (Join-Path $packDir "70-audit-release-readiness.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\audit-release-readiness.ps1') -Version $releaseVersionLiteral -Mode $modeLiteral -RunLabel $runLabelLiteral -EvidencePackPath $evidencePackPathLiteral -RepoRoot `$repoRoot
"@

$readmeContent = @"
# Lumina-OS Release Validation Action Pack

- Generated At: $(Get-Date -Format s)
- Release Execution: $resolvedExecutionPath
- Run Label: $runLabel
- Release Version: $releaseVersionValue
- Mode: $mode
- Cycle Handoff: $cycleHandoffPath
- Evidence Session: $evidenceSessionPath
- Evidence Pack: $evidencePackPath
- Evidence Runbook: $evidenceRunbookPath
- Execution Runbook: $executionRunbookPath
- Workboard: $workboardPath
- Current Evidence Session: $currentEvidenceSessionPath
- Current Release Control Center: $currentControlCenterPath

## Helpers
- `00-run-next-step.ps1`
- `10-open-cycle-handoff.ps1`
- `20-open-next-evidence.ps1`
- `21-open-login-test-report.ps1`
- `22-open-install-report.ps1`
- `23-open-hardware-report.ps1`
- `30-sync-evidence-session.ps1`
- `31-sync-release-validation-pass.ps1`
- `40-open-control-center.ps1`
- `41-open-execution-runbook.ps1`
- `42-open-workboard.ps1`
- `50-audit-release-evidence.ps1`
- `60-prepare-release-candidate.ps1`
- `70-audit-release-readiness.ps1`

## Direct Evidence Paths
- Login-Test Report: $loginTestReportPath
- Install Report: $installReportPath
- Hardware Report: $hardwareReportPath

## Goal
- reduce friction between runbook/workboard reading and real evidence execution
- keep one folder with direct helper scripts for the current release validation pass
- let one launcher resolve and run the next practical release-validation step automatically
"@

Set-Content -Path $packReadmePath -Value $readmeContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $packReadmePath
}
else {
    Write-Host "Created release validation action pack:"
    Write-Host $packReadmePath
}
