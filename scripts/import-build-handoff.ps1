param(
    [Parameter(Mandatory = $true)]
    [string]$HandoffPath,
    [string]$Label = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-SafeSegment {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unknown"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\.-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unknown"
    }

    return $safe
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

$buildManifestImporter = Join-Path $PSScriptRoot "import-build-manifest.ps1"
$isoImporter = Join-Path $PSScriptRoot "import-iso-artifact.ps1"

if (-not (Test-Path $buildManifestImporter)) {
    throw "Missing helper: $buildManifestImporter"
}

if (-not (Test-Path $isoImporter)) {
    throw "Missing helper: $isoImporter"
}

if (-not (Test-Path $HandoffPath)) {
    throw "Build handoff path not found: $HandoffPath"
}

$resolvedHandoffPath = (Resolve-Path $HandoffPath).Path
$handoffItem = Get-Item $resolvedHandoffPath

if (-not $handoffItem.PSIsContainer) {
    throw "Build handoff import expects a directory path: $resolvedHandoffPath"
}

$handoffManifestPath = Join-Path $resolvedHandoffPath "handoff-manifest.md"
$handoffManifestContent = if (Test-Path $handoffManifestPath) { Get-Content -Raw $handoffManifestPath } else { "" }

$manifestCandidate = Get-ChildItem -Path $resolvedHandoffPath -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "handoff-manifest.md" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$isoCandidate = Get-ChildItem -Path $resolvedHandoffPath -Filter "*.iso" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $manifestCandidate) {
    throw "Could not find a build manifest file inside the handoff folder."
}

if (-not $isoCandidate) {
    throw "Could not find an ISO file inside the handoff folder."
}

$manifestContent = Get-Content -Raw $manifestCandidate.FullName
$reportedMode = Get-MetadataValue -Content $manifestContent -Label "Mode"
$reportedRunLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$labelValue = if ([string]::IsNullOrWhiteSpace($Label)) { $reportedRunLabel } else { $Label.Trim() }
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$labelSegment = Get-SafeSegment $(if ([string]::IsNullOrWhiteSpace($labelValue)) { Split-Path $resolvedHandoffPath -Leaf } else { $labelValue })
$handoffImportsRoot = Join-Path $RepoRoot ("status\build-handoffs\" + $dateStamp)
$importDir = Join-Path $handoffImportsRoot ($timeStamp + "-" + $labelSegment)
$summaryPath = Join-Path $importDir "import-summary.md"

New-Item -ItemType Directory -Force -Path $importDir | Out-Null

$importedManifestPath = & $buildManifestImporter `
    -ManifestPath $manifestCandidate.FullName `
    -Label $labelValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$importedIsoPath = & $isoImporter `
    -IsoPath $isoCandidate.FullName `
    -Mode $(if ([string]::IsNullOrWhiteSpace($reportedMode)) { "unknown" } else { $reportedMode }) `
    -RunLabel $reportedRunLabel `
    -Label $labelValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$summaryContent = @"
# Lumina-OS Build Handoff Import

- Imported At: $(Get-Date -Format s)
- Handoff Path: $resolvedHandoffPath
- Handoff Manifest: $(if (Test-Path $handoffManifestPath) { $handoffManifestPath } else { "not-recorded-yet" })
- Import Label: $(if ([string]::IsNullOrWhiteSpace($labelValue)) { "not-recorded-yet" } else { $labelValue })
- Reported Mode: $(if ([string]::IsNullOrWhiteSpace($reportedMode)) { "unknown" } else { $reportedMode })
- Reported Run Label: $(if ([string]::IsNullOrWhiteSpace($reportedRunLabel)) { "not-recorded-yet" } else { $reportedRunLabel })
- Imported Build Manifest: $importedManifestPath
- Imported ISO Path: $importedIsoPath

## Source Files
- Source Build Manifest: $($manifestCandidate.FullName)
- Source ISO Path: $($isoCandidate.FullName)

## Next Step
- reuse the same run label in `start-vm-test-cycle.ps1`
- later run `prepare-release-candidate.ps1` from this workspace against the imported ISO and linked evidence
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Imported Lumina-OS build handoff:"
    Write-Host "Summary:           $summaryPath"
    Write-Host "Build Manifest:    $importedManifestPath"
    Write-Host "Imported ISO Path: $importedIsoPath"
}
