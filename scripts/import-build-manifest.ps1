param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
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

if (-not (Test-Path $ManifestPath)) {
    throw "Build manifest path not found: $ManifestPath"
}

$resolvedManifestPath = (Resolve-Path $ManifestPath).Path
$manifestContent = Get-Content -Raw $resolvedManifestPath
$reportedMode = Get-MetadataValue -Content $manifestContent -Label "Mode"
$reportedRunLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$reportedBuiltAt = Get-MetadataValue -Content $manifestContent -Label "Built At"
$reportedIsoPath = Get-MetadataValue -Content $manifestContent -Label "Full Path"

$modeSegment = Get-SafeSegment $(if ([string]::IsNullOrWhiteSpace($reportedMode)) { "unknown" } else { $reportedMode })
$labelValue = if ([string]::IsNullOrWhiteSpace($Label)) { $reportedRunLabel } else { $Label.Trim() }
$labelSegment = Get-SafeSegment $(if ([string]::IsNullOrWhiteSpace($labelValue)) { Split-Path $resolvedManifestPath -LeafBase } else { $labelValue })
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$buildsDir = Join-Path $RepoRoot ("status\builds\" + $dateStamp)
$importsDir = Join-Path $RepoRoot ("status\build-imports\" + $dateStamp)
$importDir = Join-Path $importsDir ($timeStamp + "-" + $labelSegment)
$importedManifestPath = Join-Path $buildsDir ("build-imported-" + $timeStamp + "-" + $modeSegment + "-" + $labelSegment + ".md")
$importRecordPath = Join-Path $importDir "import-manifest.md"

New-Item -ItemType Directory -Force -Path $buildsDir | Out-Null
New-Item -ItemType Directory -Force -Path $importDir | Out-Null

Copy-Item -LiteralPath $resolvedManifestPath -Destination $importedManifestPath -Force

$recordContent = @"
# Lumina-OS Build Manifest Import

- Imported At: $(Get-Date -Format s)
- Import Label: $(if ([string]::IsNullOrWhiteSpace($labelValue)) { "not-recorded-yet" } else { $labelValue })
- Source Path: $resolvedManifestPath
- Imported Manifest: $importedManifestPath
- Reported Built At: $(if ([string]::IsNullOrWhiteSpace($reportedBuiltAt)) { "not-recorded-yet" } else { $reportedBuiltAt })
- Reported Mode: $(if ([string]::IsNullOrWhiteSpace($reportedMode)) { "unknown" } else { $reportedMode })
- Reported Run Label: $(if ([string]::IsNullOrWhiteSpace($reportedRunLabel)) { "not-recorded-yet" } else { $reportedRunLabel })
- Reported ISO Path: $(if ([string]::IsNullOrWhiteSpace($reportedIsoPath)) { "not-recorded-yet" } else { $reportedIsoPath })

## Next Step
- use the imported manifest path during `start-vm-test-cycle.ps1` if the build happened in a separate Arch clone
"@

Set-Content -Path $importRecordPath -Value $recordContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $importedManifestPath
}
else {
    Write-Host "Imported Lumina-OS build manifest:"
    Write-Host "Manifest: $importedManifestPath"
    Write-Host "Record:   $importRecordPath"
}
