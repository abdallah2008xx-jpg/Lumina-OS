param(
    [Parameter(Mandatory = $true)]
    [string]$BundlePath,
    [string]$Label = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-SafeLabel {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "bundle"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "bundle"
    }

    return $safe
}

if (-not (Test-Path $BundlePath)) {
    throw "Diagnostics bundle path not found: $BundlePath"
}

$resolvedBundlePath = (Resolve-Path $BundlePath).Path
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$labelValue = if ([string]::IsNullOrWhiteSpace($Label)) { Split-Path $resolvedBundlePath -Leaf } else { $Label }
$safeLabel = Get-SafeLabel $labelValue
$diagnosticsRoot = Join-Path $RepoRoot ("status\diagnostics\" + $dateStamp)
$importDir = Join-Path $diagnosticsRoot ($timeStamp + "-" + $safeLabel)
$bundleDir = Join-Path $importDir "bundle"
$manifestPath = Join-Path $importDir "import-manifest.md"

New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null

$bundleItem = Get-Item $resolvedBundlePath
$bundleKind = if ($bundleItem.PSIsContainer) { "directory" } else { "file" }
$copiedArchivePath = ""
$extractState = "not-attempted"

if ($bundleItem.PSIsContainer) {
    $bundleEntries = Get-ChildItem -LiteralPath $resolvedBundlePath -Force -ErrorAction SilentlyContinue
    if ($bundleEntries) {
        $bundleEntries | Copy-Item -Destination $bundleDir -Recurse -Force
    }
    $extractState = "copied-directory"
}
else {
    $copiedArchivePath = Join-Path $importDir $bundleItem.Name
    Copy-Item -LiteralPath $resolvedBundlePath -Destination $copiedArchivePath -Force

    $isTarGz = $bundleItem.Extension -in @(".gz", ".tgz") -or $bundleItem.Name.ToLowerInvariant().EndsWith(".tar.gz")
    if ($isTarGz -and (Get-Command tar -ErrorAction SilentlyContinue)) {
        tar -xf $copiedArchivePath -C $bundleDir
        if ($LASTEXITCODE -eq 0) {
            $extractState = "extracted"
        }
        else {
            $extractState = "copied-archive-only"
        }
    }
    else {
        $extractState = "copied-archive-only"
    }
}

$summaryPath = Get-ChildItem -Path $bundleDir -Recurse -Filter "summary.md" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
$firstbootPath = Get-ChildItem -Path $bundleDir -Recurse -Filter "firstboot-report.md" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
$smokePath = Get-ChildItem -Path $bundleDir -Recurse -Filter "smoke-check-report.md" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$summaryDisplay = if ($summaryPath) { $summaryPath.FullName } else { "not-found" }
$firstbootDisplay = if ($firstbootPath) { $firstbootPath.FullName } else { "not-found" }
$smokeDisplay = if ($smokePath) { $smokePath.FullName } else { "not-found" }
$archiveDisplay = if ([string]::IsNullOrWhiteSpace($copiedArchivePath)) { "not-copied" } else { $copiedArchivePath }

$topLevelEntries = Get-ChildItem -Path $bundleDir -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
$topLevelList = if ($topLevelEntries) { ($topLevelEntries -join ", ") } else { "none" }

$content = @"
# AhmadOS Diagnostics Import

- Imported At: $(Get-Date -Format s)
- Import Label: $labelValue
- Source Path: $resolvedBundlePath
- Source Kind: $bundleKind
- Import Directory: $importDir
- Archive Copy: $archiveDisplay
- Extraction State: $extractState

## Discovered Files
- Summary: $summaryDisplay
- Firstboot Report: $firstbootDisplay
- Smoke Check Report: $smokeDisplay

## Top-Level Entries
- $topLevelList

## Next Step
- reference this import manifest from status/test-sessions/
"@

Set-Content -Path $manifestPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $manifestPath
}
else {
    Write-Host "Imported diagnostics bundle:"
    Write-Host $manifestPath
}
