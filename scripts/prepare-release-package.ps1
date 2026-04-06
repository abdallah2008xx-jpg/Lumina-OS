param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$IsoPath = "",
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "stable",
    [string]$RunLabel = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$InstallReportPath = "",
    [string]$HardwareReportPath = "",
    [string]$SessionPath = "",
    [string]$AuditPath = "",
    [string]$CycleChainAuditPath = "",
    [string]$ReadinessPath = "",
    [string]$ValidationMatrixPath = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

function Get-LatestFile {
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

function Get-LatestModeFile {
    param(
        [string]$Path,
        [string]$Filter,
        [string]$Mode
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $escapedMode = [regex]::Escape($Mode)
    $pattern = "-" + $escapedMode + "([\.-]|$)"

    return Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "CURRENT-*.md" } |
        Where-Object {
            if ($_.Name -match $pattern) {
                return $true
            }

            $content = Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue
            return ($content -match ("(?m)^- Mode: " + $escapedMode + "$"))
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

function Test-EvidencePassState {
    param(
        [string]$Content,
        [string[]]$StatusLabels,
        [string[]]$PassStates
    )

    $status = Get-StateValue -Content $Content -Labels $StatusLabels
    if ([string]::IsNullOrWhiteSpace($status)) {
        return $false
    }

    return ($PassStates -contains $status.Trim().ToLowerInvariant())
}

function Get-ReportMetadata {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        return @{
            RunLabel = ""
            Status = ""
        }
    }

    $content = Get-Content -Raw $Path -ErrorAction SilentlyContinue
    return @{
        RunLabel = Get-MetadataValue -Content $content -Label "Run Label"
        Status = Get-StateValue -Content $content -Labels @("Overall Status", "Hardware Readiness", "Overall State", "Result")
    }
}

function Get-BestEvidenceFile {
    param(
        [string]$Path,
        [string]$Filter,
        [string]$RunLabel,
        [string]$Mode,
        [string[]]$StatusLabels,
        [string[]]$PassStates,
        [switch]$UseModeFilter
    )

    $result = @{
        File = $null
        Selection = "not-found"
    }

    if (-not (Test-Path $Path)) {
        return $result
    }

    if (-not [string]::IsNullOrWhiteSpace($RunLabel)) {
        $runMatch = Get-FileByRunLabel -Path $Path -Filter $Filter -RunLabel $RunLabel
        if ($runMatch) {
            $result.File = $runMatch
            $result.Selection = "exact-run-label"
            return $result
        }
    }

    $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "CURRENT-*.md" } |
        Sort-Object LastWriteTime -Descending

    if ($UseModeFilter.IsPresent -and -not [string]::IsNullOrWhiteSpace($Mode)) {
        $escapedMode = [regex]::Escape($Mode)
        $pattern = "-" + $escapedMode + "([\.-]|$)"
        $files = $files | Where-Object {
            if ($_.Name -match $pattern) {
                return $true
            }

            $content = Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue
            return ($content -match ("(?m)^- Mode: " + $escapedMode + "$"))
        }
    }

    foreach ($file in $files) {
        $content = Get-Content -Raw $file.FullName -ErrorAction SilentlyContinue
        if (Test-EvidencePassState -Content $content -StatusLabels $StatusLabels -PassStates $PassStates) {
            $result.File = $file
            $result.Selection = if ($UseModeFilter.IsPresent -and -not [string]::IsNullOrWhiteSpace($Mode)) { "latest-completed-mode" } else { "latest-completed" }
            return $result
        }
    }

    $fallback = $files | Select-Object -First 1
    if ($fallback) {
        $result.File = $fallback
        $result.Selection = if ($UseModeFilter.IsPresent -and -not [string]::IsNullOrWhiteSpace($Mode)) { "latest-mode" } else { "latest-any" }
    }

    return $result
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

function Get-ImportedIsoPath {
    param(
        [string]$RepoRoot,
        [string]$RunLabel,
        [string]$Mode
    )

    $importsRoot = Join-Path $RepoRoot "status\iso-imports"
    if (-not (Test-Path $importsRoot)) {
        return ""
    }

    $importFiles = Get-ChildItem -Path $importsRoot -Filter "import-manifest.md" -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    foreach ($importFile in $importFiles) {
        $content = Get-Content -Raw $importFile.FullName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        $recordedRunLabel = Get-MetadataValue -Content $content -Label "Run Label"
        $recordedMode = Get-MetadataValue -Content $content -Label "Mode"
        $importedIsoPath = Get-MetadataValue -Content $content -Label "Imported ISO Path"

        if ([string]::IsNullOrWhiteSpace($importedIsoPath) -or -not (Test-Path $importedIsoPath)) {
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($RunLabel) -and $recordedRunLabel -eq $RunLabel) {
            return (Resolve-Path $importedIsoPath).Path
        }

        if ([string]::IsNullOrWhiteSpace($RunLabel) -and -not [string]::IsNullOrWhiteSpace($Mode) -and $recordedMode -eq $Mode) {
            return (Resolve-Path $importedIsoPath).Path
        }
    }

    return ""
}

function Get-ChangelogUnreleasedSection {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return "- changelog not found"
    }

    $content = Get-Content -Raw $Path
    $match = [regex]::Match($content, "(?s)^## Unreleased\s*(?<body>.*?)(?=^## |\z)", [System.Text.RegularExpressions.RegexOptions]::Multiline)

    if (-not $match.Success) {
        return "- no unreleased changelog section found"
    }

    $body = $match.Groups["body"].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($body)) {
        return "- unreleased changelog section is empty"
    }

    return $body
}

$resolvedBuildManifestPath = $BuildManifestPath
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode
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
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -Mode $Mode
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedVmReportPath = $candidate.FullName
    }
}

$resolvedInstallReportPath = $InstallReportPath
$installReportSelection = if ([string]::IsNullOrWhiteSpace($resolvedInstallReportPath)) { "auto" } else { "explicit-path" }
if ([string]::IsNullOrWhiteSpace($resolvedInstallReportPath)) {
    $candidateSelection = Get-BestEvidenceFile `
        -Path (Join-Path $RepoRoot "status\install-tests") `
        -Filter "*.md" `
        -RunLabel $RunLabel `
        -Mode $Mode `
        -StatusLabels @("Overall Status", "Overall State", "Result") `
        -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-release") `
        -UseModeFilter

    if ($candidateSelection.File) {
        $resolvedInstallReportPath = $candidateSelection.File.FullName
        $installReportSelection = $candidateSelection.Selection
    }
}

$resolvedHardwareReportPath = $HardwareReportPath
$hardwareReportSelection = if ([string]::IsNullOrWhiteSpace($resolvedHardwareReportPath)) { "auto" } else { "explicit-path" }
if ([string]::IsNullOrWhiteSpace($resolvedHardwareReportPath)) {
    $candidateSelection = Get-BestEvidenceFile `
        -Path (Join-Path $RepoRoot "status\hardware-tests") `
        -Filter "*.md" `
        -RunLabel $RunLabel `
        -Mode $Mode `
        -StatusLabels @("Overall Status", "Hardware Readiness", "Overall State", "Result") `
        -PassStates @("pass", "passed", "complete", "completed", "success", "successful", "ready-for-real-device-smoke", "ready-for-release") 

    if ($candidateSelection.File) {
        $resolvedHardwareReportPath = $candidateSelection.File.FullName
        $hardwareReportSelection = $candidateSelection.Selection
    }
}

$resolvedSessionPath = $SessionPath
if ([string]::IsNullOrWhiteSpace($resolvedSessionPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md" -Mode $Mode
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
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md" -Mode $Mode
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedAuditPath = $candidate.FullName
    }
}

$resolvedCycleChainAuditPath = $CycleChainAuditPath
if ([string]::IsNullOrWhiteSpace($resolvedCycleChainAuditPath)) {
    $candidate = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestFile -Path (Join-Path $RepoRoot "status\cycle-chain-audits") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\cycle-chain-audits") -Filter "*.md" -RunLabel $RunLabel
    }

    if ($candidate) {
        $resolvedCycleChainAuditPath = $candidate.FullName
    }
}

$resolvedReadinessPath = if ([string]::IsNullOrWhiteSpace($ReadinessPath)) {
    Join-Path $RepoRoot "status\readiness\CURRENT-READINESS.md"
}
else {
    $ReadinessPath
}

$resolvedValidationMatrixPath = if ([string]::IsNullOrWhiteSpace($ValidationMatrixPath)) {
    Join-Path $RepoRoot "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md"
}
else {
    $ValidationMatrixPath
}

$buildContent = if (-not [string]::IsNullOrWhiteSpace($resolvedBuildManifestPath) -and (Test-Path $resolvedBuildManifestPath)) { Get-Content -Raw $resolvedBuildManifestPath } else { "" }
$resolvedIsoPath = $IsoPath

if ([string]::IsNullOrWhiteSpace($resolvedIsoPath) -and -not [string]::IsNullOrWhiteSpace($buildContent)) {
    $resolvedIsoPath = Get-MetadataValue -Content $buildContent -Label "Full Path"
}

if ([string]::IsNullOrWhiteSpace($resolvedIsoPath) -or $resolvedIsoPath -in @("not-found", "not-recorded-yet")) {
    $resolvedIsoPath = Get-ImportedIsoPath -RepoRoot $RepoRoot -RunLabel $RunLabel -Mode $Mode
}

if ([string]::IsNullOrWhiteSpace($resolvedIsoPath) -or $resolvedIsoPath -in @("not-found", "not-recorded-yet")) {
    throw "ISO path is required. Pass -IsoPath, import a local ISO artifact, or provide a build manifest with a real Full Path."
}

if (-not (Test-Path $resolvedIsoPath)) {
    $importedIsoFallback = Get-ImportedIsoPath -RepoRoot $RepoRoot -RunLabel $RunLabel -Mode $Mode
    if (-not [string]::IsNullOrWhiteSpace($importedIsoFallback)) {
        $resolvedIsoPath = $importedIsoFallback
    }
}

if (-not (Test-Path $resolvedIsoPath)) {
    throw "ISO path not found: $resolvedIsoPath"
}

$resolvedIsoPath = (Resolve-Path $resolvedIsoPath).Path
$isoItem = Get-Item $resolvedIsoPath
$sha256 = (Get-FileHash -Algorithm SHA256 -Path $resolvedIsoPath).Hash.ToLowerInvariant()
$sizeBytes = $isoItem.Length
$isoName = $isoItem.Name

$versionLabel = $Version.Trim()
$safeVersion = Get-SafeFileSegment $versionLabel
$safeMode = Get-SafeFileSegment $Mode
$safeRunLabel = Get-SafeFileSegment $RunLabel
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$releaseRoot = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$releaseDirName = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
    "release-$safeVersion-$safeMode"
}
else {
    "release-$safeVersion-$safeRunLabel"
}
$releaseDir = Join-Path $releaseRoot $releaseDirName
$manifestPath = Join-Path $releaseDir "release-manifest.md"
$releaseNotesPath = Join-Path $releaseDir "release-notes.md"
$checksumPath = Join-Path $releaseDir "SHA256SUMS.txt"
$changelogPath = Join-Path $RepoRoot "CHANGELOG.md"

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$checksumContent = "$sha256 *$isoName"
Set-Content -Path $checksumPath -Value $checksumContent -Encoding ASCII

$installReportMetadata = Get-ReportMetadata -Path $resolvedInstallReportPath
$hardwareReportMetadata = Get-ReportMetadata -Path $resolvedHardwareReportPath

$releaseEvidenceLines = @(
    "- Build Manifest: $(Get-ResolvedPathOrDefault -Value $resolvedBuildManifestPath -DefaultValue "not-recorded-yet")",
    "- VM Report: $(Get-ResolvedPathOrDefault -Value $resolvedVmReportPath -DefaultValue "not-recorded-yet")",
    "- Install Report: $(Get-ResolvedPathOrDefault -Value $resolvedInstallReportPath -DefaultValue "not-recorded-yet")",
    "- Install Report Run Label: $(Get-ResolvedPathOrDefault -Value $installReportMetadata.RunLabel -DefaultValue "not-recorded-yet")",
    "- Install Report Selection: $(Get-ResolvedPathOrDefault -Value $installReportSelection -DefaultValue "not-recorded-yet")",
    "- Hardware Report: $(Get-ResolvedPathOrDefault -Value $resolvedHardwareReportPath -DefaultValue "not-recorded-yet")",
    "- Hardware Report Run Label: $(Get-ResolvedPathOrDefault -Value $hardwareReportMetadata.RunLabel -DefaultValue "not-recorded-yet")",
    "- Hardware Report Selection: $(Get-ResolvedPathOrDefault -Value $hardwareReportSelection -DefaultValue "not-recorded-yet")",
    "- Session Summary: $(Get-ResolvedPathOrDefault -Value $resolvedSessionPath -DefaultValue "not-recorded-yet")",
    "- Session Audit: $(Get-ResolvedPathOrDefault -Value $resolvedAuditPath -DefaultValue "not-recorded-yet")",
    "- Cycle Chain Audit: $(Get-ResolvedPathOrDefault -Value $resolvedCycleChainAuditPath -DefaultValue "not-recorded-yet")",
    "- Readiness: $(Get-ResolvedPathOrDefault -Value $resolvedReadinessPath -DefaultValue "not-recorded-yet")",
    "- Validation Matrix: $(Get-ResolvedPathOrDefault -Value $resolvedValidationMatrixPath -DefaultValue "not-recorded-yet")"
) -join "`r`n"

$manifestContent = @"
# Lumina-OS Release Manifest

- Prepared At: $(Get-Date -Format s)
- Version: $versionLabel
- Mode: $Mode
- Run Label: $(if ([string]::IsNullOrWhiteSpace($RunLabel)) { "not-recorded-yet" } else { $RunLabel })
- ISO File: $isoName
- ISO Path: $resolvedIsoPath
- ISO Size Bytes: $sizeBytes
- SHA256: $sha256
- Checksum File: $checksumPath
- Release Notes: $releaseNotesPath

## Evidence Links
$releaseEvidenceLines

## Upload Package
- ISO asset: $resolvedIsoPath
- Checksum asset: $checksumPath
- Release notes source: $releaseNotesPath

## Next Step
- validate the package with `scripts/validate-release-package.ps1`
- publish the package with `scripts/publish-github-release.ps1`
- upload or verify the ISO and `SHA256SUMS.txt` assets in GitHub Releases
- paste or adapt the contents of `release-notes.md` if a final wording pass is still needed
- verify the linked evidence still reflects the intended release candidate
"@

$unreleasedSection = Get-ChangelogUnreleasedSection -Path $changelogPath
$notesContent = @"
# Lumina-OS $versionLabel

## Release Summary
- draft this summary for the GitHub Release description

## Included Asset
- `$isoName`

## Validation Scope
- Mode: $Mode
- Run Label: $(if ([string]::IsNullOrWhiteSpace($RunLabel)) { "not-recorded-yet" } else { $RunLabel })

## Evidence Links
$releaseEvidenceLines

## Changelog Snapshot
$unreleasedSection

## Known Issues
- add any known issue here before publishing

## Notes
- this file is a draft source for the GitHub Release body
"@

Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
Set-Content -Path $releaseNotesPath -Value $notesContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $manifestPath
}
else {
    Write-Host "Prepared Lumina-OS release package:"
    Write-Host "Manifest:      $manifestPath"
    Write-Host "Release Notes: $releaseNotesPath"
    Write-Host "Checksums:     $checksumPath"
}
