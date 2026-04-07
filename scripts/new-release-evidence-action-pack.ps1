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

if (-not (Test-Path $EvidenceSessionPath)) {
    throw "Evidence session path not found: $EvidenceSessionPath"
}

$openNextEvidenceScript = Join-Path $PSScriptRoot "open-next-release-evidence.ps1"
$openNextReleaseActionScript = Join-Path $PSScriptRoot "open-next-release-action.ps1"
$syncEvidenceSessionScript = Join-Path $PSScriptRoot "sync-release-evidence-session.ps1"

foreach ($requiredScript in @($openNextEvidenceScript, $openNextReleaseActionScript, $syncEvidenceSessionScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

$resolvedEvidenceSessionPath = (Resolve-Path $EvidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$runLabel = Get-RecordedValue -Content $sessionContent -Label "Run Label"
$mode = Get-RecordedValue -Content $sessionContent -Label "Mode" -DefaultValue "stable"
$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Get-RecordedValue -Content $sessionContent -Label "Release Version" -DefaultValue "0.1.0-dev"
}
else {
    $ReleaseVersion.Trim()
}
$evidencePackPath = Get-RecordedValue -Content $sessionContent -Label "Evidence Pack" -DefaultValue ""
$runbookPath = Get-RecordedValue -Content $sessionContent -Label "Runbook Path" -DefaultValue ""
$loginTestReportPath = Get-RecordedValue -Content $sessionContent -Label "Login-Test Report" -DefaultValue ""
$installReportPath = Get-RecordedValue -Content $sessionContent -Label "Install Report" -DefaultValue ""
$hardwareReportPath = Get-RecordedValue -Content $sessionContent -Label "Hardware Report" -DefaultValue ""
$currentControlCenterPath = Get-RecordedValue -Content $sessionContent -Label "Current Release Control Center" -DefaultValue ""
if ($currentControlCenterPath -eq "not-recorded-yet" -or [string]::IsNullOrWhiteSpace($currentControlCenterPath)) {
    $currentControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"
}

$safeRunLabel = Get-SafeFileSegment $runLabel
$sessionDir = Split-Path -Parent $resolvedEvidenceSessionPath
$packDir = Join-Path $sessionDir ("release-evidence-actions-" + $safeRunLabel)
$packReadmePath = Join-Path $packDir "README.md"

New-Item -ItemType Directory -Force -Path $packDir | Out-Null

$repoRootLiteral = Convert-ToPsLiteral $RepoRoot
$sessionPathLiteral = Convert-ToPsLiteral $resolvedEvidenceSessionPath
$releaseVersionLiteral = Convert-ToPsLiteral $releaseVersionValue
$loginTestPathLiteral = Convert-ToPsLiteral $loginTestReportPath
$installPathLiteral = Convert-ToPsLiteral $installReportPath
$hardwarePathLiteral = Convert-ToPsLiteral $hardwareReportPath
$runbookPathLiteral = Convert-ToPsLiteral $runbookPath
$controlCenterPathLiteral = Convert-ToPsLiteral $currentControlCenterPath

Write-HelperScript -Path (Join-Path $packDir "00-run-next-step.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\open-next-release-evidence.ps1') -EvidenceSessionPath $sessionPathLiteral -RepoRoot `$repoRoot -Open
"@

Write-HelperScript -Path (Join-Path $packDir "10-open-login-test-report.ps1") -Body @"
`$path = $loginTestPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Login-test report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "11-open-install-report.ps1") -Body @"
`$path = $installPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Install report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "12-open-hardware-report.ps1") -Body @"
`$path = $hardwarePathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Hardware report not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "20-open-evidence-runbook.ps1") -Body @"
`$path = $runbookPathLiteral
if (Test-Path `$path) {
    Invoke-Item -LiteralPath `$path
}
else {
    throw "Evidence runbook not found: `$path"
}
"@

Write-HelperScript -Path (Join-Path $packDir "30-sync-evidence-session.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\sync-release-evidence-session.ps1') -EvidenceSessionPath $sessionPathLiteral -ReleaseVersion $releaseVersionLiteral -RepoRoot `$repoRoot
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

Write-HelperScript -Path (Join-Path $packDir "50-open-release-next-action.ps1") -Body @"
`$repoRoot = $repoRootLiteral
& (Join-Path `$repoRoot 'scripts\open-next-release-action.ps1') -RepoRoot `$repoRoot -Open
"@

$readmeContent = @"
# Lumina-OS Release Evidence Action Pack

- Generated At: $(Get-Date -Format s)
- Evidence Session: $resolvedEvidenceSessionPath
- Run Label: $runLabel
- Release Version: $releaseVersionValue
- Mode: $mode
- Evidence Pack: $evidencePackPath
- Evidence Runbook: $runbookPath
- Current Release Control Center: $currentControlCenterPath

## Helpers
- `00-run-next-step.ps1`
- `10-open-login-test-report.ps1`
- `11-open-install-report.ps1`
- `12-open-hardware-report.ps1`
- `20-open-evidence-runbook.ps1`
- `30-sync-evidence-session.ps1`
- `40-open-control-center.ps1`
- `50-open-release-next-action.ps1`

## Direct Evidence Paths
- Login-Test Report: $loginTestReportPath
- Install Report: $installReportPath
- Hardware Report: $hardwareReportPath

## Goal
- keep one small folder for the current evidence session
- jump directly to the next missing evidence target
- keep sync and release-control review one click away while collecting real evidence
"@

Set-Content -Path $packReadmePath -Value $readmeContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $packReadmePath
}
else {
    Write-Host "Created release evidence action pack:"
    Write-Host $packReadmePath
}
