param(
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$DiagnosticsBundlePath = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$DiagnosticsImportPath = "",
    [string]$RunLabel = "",
    [string]$SessionPath = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-LatestFile {
    param(
        [string]$Path,
        [string]$Filter
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    return Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
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
    $pattern = "-" + $escapedMode + "([\\.-]|$)"

    return Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue |
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

function Get-RecordedValue {
    param(
        [string]$PreferredValue,
        [string]$FallbackValue
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredValue)) {
        return $PreferredValue
    }

    return $FallbackValue
}

function Test-FileMatchesRunLabel {
    param(
        [string]$Path,
        [string]$RunLabel
    )

    if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        return $true
    }

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        return $false
    }

    $escapedRunLabel = [regex]::Escape($RunLabel)
    if ([System.IO.Path]::GetFileName($Path) -match $escapedRunLabel) {
        return $true
    }

    $content = Get-Content -Raw $Path -ErrorAction SilentlyContinue
    return ($content -match ("(?m)^- Run Label: " + $escapedRunLabel + "$"))
}

function Get-ExistingMetadataValue {
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

function Get-ChecklistMark {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "not-recorded-yet") {
        return " "
    }

    return "x"
}

function Get-SafeFileSegment {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unnamed"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

function Get-DefaultTail {
    return @"
## Findings
- none yet

## Blockers
- none yet

## Decision Summary
- continue / fix blockers / rebuild

## Notes
- link the exact diagnostics bundle path here
- update the diagnostics import path here if a newer import is created later
- copy key blockers from the VM report here
- note whether another rebuild is required
"@
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeVmType = $VmType.ToLower().Replace(" ", "-")
$sessionDir = Join-Path $RepoRoot ("status\test-sessions\" + $dateStamp)
$targetSessionPath = $SessionPath

$existingContent = ""
if (-not [string]::IsNullOrWhiteSpace($targetSessionPath) -and (Test-Path $targetSessionPath)) {
    $existingContent = Get-Content -Raw $targetSessionPath
}

$existingRunLabel = Get-ExistingMetadataValue -Content $existingContent -Label "Run Label"
$vmReportContent = if (-not [string]::IsNullOrWhiteSpace($VmReportPath) -and (Test-Path $VmReportPath)) { Get-Content -Raw $VmReportPath } else { "" }
$vmReportRunLabel = Get-ExistingMetadataValue -Content $vmReportContent -Label "Run Label"
$resolvedRunLabel = Get-RecordedValue -PreferredValue $RunLabel -FallbackValue (Get-RecordedValue -PreferredValue $vmReportRunLabel -FallbackValue (Get-RecordedValue -PreferredValue $existingRunLabel -FallbackValue "$timeStamp-$Mode-$safeVmType"))
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$sessionName = "test-session-$safeRunLabel.md"

if ([string]::IsNullOrWhiteSpace($targetSessionPath)) {
    $targetSessionPath = Join-Path $sessionDir $sessionName
}

New-Item -ItemType Directory -Force -Path (Split-Path $targetSessionPath -Parent) | Out-Null

$latestBuildManifest = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode
}
else {
    $byRunLabel = Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -RunLabel $resolvedRunLabel
    if ($byRunLabel) { $byRunLabel } else { Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode }
}
$latestVmReport = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -Mode $Mode
$latestDiagnosticsImport = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    Get-LatestFile -Path (Join-Path $RepoRoot "status\diagnostics") -Filter "import-manifest.md"
}
else {
    Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\diagnostics") -Filter "import-manifest.md" -RunLabel $resolvedRunLabel
}

$existingBuildManifestPath = Get-ExistingMetadataValue -Content $existingContent -Label "Build Manifest"
$existingVmReportPath = Get-ExistingMetadataValue -Content $existingContent -Label "VM Report"
$existingIsoPath = Get-ExistingMetadataValue -Content $existingContent -Label "ISO Path"
$existingDiagnosticsBundlePath = Get-ExistingMetadataValue -Content $existingContent -Label "Diagnostics Bundle"
$existingDiagnosticsImportPath = Get-ExistingMetadataValue -Content $existingContent -Label "Diagnostics Import"
$existingDiagnosticsImportPath = if (Test-FileMatchesRunLabel -Path $existingDiagnosticsImportPath -RunLabel $resolvedRunLabel) { $existingDiagnosticsImportPath } else { "" }

$buildManifestPath = Get-RecordedValue -PreferredValue $BuildManifestPath -FallbackValue (Get-RecordedValue -PreferredValue $(if ($latestBuildManifest) { $latestBuildManifest.FullName } else { "" }) -FallbackValue $(if ([string]::IsNullOrWhiteSpace($existingBuildManifestPath)) { "not-recorded-yet" } else { $existingBuildManifestPath }))
$vmReportPath = Get-RecordedValue -PreferredValue $VmReportPath -FallbackValue (Get-RecordedValue -PreferredValue $(if ($latestVmReport) { $latestVmReport.FullName } else { "" }) -FallbackValue $(if ([string]::IsNullOrWhiteSpace($existingVmReportPath)) { "not-recorded-yet" } else { $existingVmReportPath }))
$isoDisplay = Get-RecordedValue -PreferredValue $IsoPath -FallbackValue $(if ([string]::IsNullOrWhiteSpace($existingIsoPath)) { "not-recorded-yet" } else { $existingIsoPath })
$diagnosticsDisplay = Get-RecordedValue -PreferredValue $DiagnosticsBundlePath -FallbackValue $(if ([string]::IsNullOrWhiteSpace($existingDiagnosticsBundlePath)) { "not-recorded-yet" } else { $existingDiagnosticsBundlePath })
$diagnosticsImportPath = Get-RecordedValue -PreferredValue $DiagnosticsImportPath -FallbackValue (Get-RecordedValue -PreferredValue $(if ($latestDiagnosticsImport) { $latestDiagnosticsImport.FullName } else { "" }) -FallbackValue $(if ([string]::IsNullOrWhiteSpace($existingDiagnosticsImportPath)) { "not-recorded-yet" } else { $existingDiagnosticsImportPath }))

$buildManifestRecorded = Get-ChecklistMark $buildManifestPath
$vmReportRecorded = Get-ChecklistMark $vmReportPath
$diagnosticsBundleRecorded = Get-ChecklistMark $diagnosticsDisplay
$diagnosticsImportRecorded = Get-ChecklistMark $diagnosticsImportPath

$header = @"
# Lumina-OS Test Session

- Date: $dateStamp
- Run Label: $resolvedRunLabel
- Mode: $Mode
- VM Type: $VmType
- Firmware: $Firmware
- ISO Path: $isoDisplay
- Build Manifest: $buildManifestPath
- VM Report: $vmReportPath
- Diagnostics Bundle: $diagnosticsDisplay
- Diagnostics Import: $diagnosticsImportPath

## Session Objectives
- confirm the ISO boots cleanly
- confirm the expected login path for the selected mode
- confirm Welcome, Update Center, and diagnostics/export flows
- capture blockers with exact reproduction notes

## Evidence Checklist
- [$buildManifestRecorded] Build manifest path recorded
- [$vmReportRecorded] VM report path recorded
- [ ] Firstboot report reviewed
- [$diagnosticsBundleRecorded] Diagnostics bundle exported
- [$diagnosticsImportRecorded] Diagnostics bundle imported into the repo
- [ ] Findings summarized below
"@

$tail = Get-DefaultTail
if (-not [string]::IsNullOrWhiteSpace($existingContent)) {
    $findingsIndex = $existingContent.IndexOf("## Findings")
    if ($findingsIndex -ge 0) {
        $tail = $existingContent.Substring($findingsIndex)
    }
}

$content = $header.TrimEnd() + "`r`n`r`n" + $tail.TrimStart()

Set-Content -Path $targetSessionPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $targetSessionPath
}
else {
    Write-Host "Created test session summary:"
    Write-Host $targetSessionPath
}
