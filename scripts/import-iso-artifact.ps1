param(
    [Parameter(Mandatory = $true)]
    [string]$IsoPath,
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "unknown",
    [string]$RunLabel = "",
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

if (-not (Test-Path $IsoPath)) {
    throw "ISO path not found: $IsoPath"
}

$resolvedIsoPath = (Resolve-Path $IsoPath).Path
$isoItem = Get-Item $resolvedIsoPath
if ($isoItem.PSIsContainer) {
    throw "ISO import expects a file path, not a directory: $resolvedIsoPath"
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$labelValue = if (-not [string]::IsNullOrWhiteSpace($Label)) {
    $Label.Trim()
}
elseif (-not [string]::IsNullOrWhiteSpace($RunLabel)) {
    $RunLabel.Trim()
}
else {
    $isoItem.BaseName
}

$safeMode = Get-SafeSegment $Mode
$safeLabel = Get-SafeSegment $labelValue
$artifactRoot = Join-Path $RepoRoot ("build\imported-iso\" + $dateStamp)
$artifactDir = Join-Path $artifactRoot ($timeStamp + "-" + $safeLabel)
$importRoot = Join-Path $RepoRoot ("status\iso-imports\" + $dateStamp)
$importDir = Join-Path $importRoot ($timeStamp + "-" + $safeLabel)
$importedIsoPath = Join-Path $artifactDir $isoItem.Name
$manifestPath = Join-Path $importDir "import-manifest.md"

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
New-Item -ItemType Directory -Force -Path $importDir | Out-Null

Copy-Item -LiteralPath $resolvedIsoPath -Destination $importedIsoPath -Force

$importedItem = Get-Item $importedIsoPath
$sha256 = (Get-FileHash -Algorithm SHA256 -Path $importedIsoPath).Hash.ToLowerInvariant()

$content = @"
# Lumina-OS ISO Artifact Import

- Imported At: $(Get-Date -Format s)
- Import Label: $labelValue
- Mode: $Mode
- Run Label: $(if ([string]::IsNullOrWhiteSpace($RunLabel)) { "not-recorded-yet" } else { $RunLabel.Trim() })
- Source ISO Path: $resolvedIsoPath
- Imported ISO Path: $importedIsoPath
- ISO File: $($importedItem.Name)
- Size Bytes: $($importedItem.Length)
- SHA256: $sha256

## Next Step
- use the imported ISO path for `prepare-release-candidate.ps1` if the original Arch-side path is not accessible from this workspace
"@

Set-Content -Path $manifestPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $importedIsoPath
}
else {
    Write-Host "Imported Lumina-OS ISO artifact:"
    Write-Host "ISO:    $importedIsoPath"
    Write-Host "Record: $manifestPath"
}
