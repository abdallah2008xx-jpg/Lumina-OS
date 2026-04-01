param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactPath,
    [string]$Label = "",
    [string]$RunId = "",
    [string]$ArtifactName = "",
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

$handoffImporter = Join-Path $PSScriptRoot "import-build-handoff.ps1"
if (-not (Test-Path $handoffImporter)) {
    throw "Missing helper: $handoffImporter"
}

if (-not (Test-Path $ArtifactPath)) {
    throw "GitHub Actions artifact path not found: $ArtifactPath"
}

$resolvedArtifactPath = (Resolve-Path $ArtifactPath).Path
$artifactItem = Get-Item $resolvedArtifactPath
$artifactType = if ($artifactItem.PSIsContainer) { "directory" } else { "file" }
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$labelValue = if (-not [string]::IsNullOrWhiteSpace($Label)) { $Label.Trim() } elseif (-not [string]::IsNullOrWhiteSpace($ArtifactName)) { $ArtifactName.Trim() } else { $artifactItem.BaseName }
$labelSegment = Get-SafeSegment $labelValue
$importsRoot = Join-Path $RepoRoot ("status\build-handoffs\" + $dateStamp)
$importDir = Join-Path $importsRoot ($timeStamp + "-gha-artifact-" + $labelSegment)
$summaryPath = Join-Path $importDir "artifact-import-summary.md"
$searchRoot = $resolvedArtifactPath
$cleanupPath = ""

New-Item -ItemType Directory -Force -Path $importDir | Out-Null

try {
    if (-not $artifactItem.PSIsContainer) {
        if ($artifactItem.Extension -ne ".zip") {
            throw "GitHub Actions artifact import expects a .zip file or an extracted directory: $resolvedArtifactPath"
        }

        $cleanupPath = Join-Path $env:TEMP ("lumina-gha-artifact-" + [guid]::NewGuid().ToString("N"))
        Expand-Archive -LiteralPath $resolvedArtifactPath -DestinationPath $cleanupPath -Force
        $searchRoot = $cleanupPath
        $artifactType = "zip"
    }

    $handoffDirs = Get-ChildItem -Path $searchRoot -Filter "handoff-manifest.md" -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty DirectoryName -Unique

    if (-not $handoffDirs -or $handoffDirs.Count -eq 0) {
        throw "Could not find any exported handoff folder inside the GitHub Actions artifact."
    }

    $importedSummaryPaths = @()

    foreach ($handoffDir in $handoffDirs) {
        $handoffManifestPath = Join-Path $handoffDir "handoff-manifest.md"
        $handoffManifestContent = Get-Content -Raw $handoffManifestPath
        $reportedMode = Get-MetadataValue -Content $handoffManifestContent -Label "Mode"
        $reportedRunLabel = Get-MetadataValue -Content $handoffManifestContent -Label "Run Label"

        $handoffLabel = ""
        if (-not [string]::IsNullOrWhiteSpace($Label)) {
            $suffix = if (-not [string]::IsNullOrWhiteSpace($reportedRunLabel)) { $reportedRunLabel } elseif (-not [string]::IsNullOrWhiteSpace($reportedMode)) { $reportedMode } else { Split-Path $handoffDir -Leaf }
            $handoffLabel = ($Label.Trim() + "-" + $suffix)
        }

        $importedSummaryPath = & $handoffImporter `
            -HandoffPath $handoffDir `
            -Label $handoffLabel `
            -RepoRoot $RepoRoot `
            -OutputPathOnly

        $importedSummaryPaths += $importedSummaryPath
    }

    $summaryLines = @(
        "# Lumina-OS GitHub Actions Artifact Import",
        "",
        "- Imported At: $(Get-Date -Format s)",
        "- Artifact Path: $resolvedArtifactPath",
        "- Artifact Type: $artifactType",
        "- Artifact Name: $(if ([string]::IsNullOrWhiteSpace($ArtifactName)) { $artifactItem.Name } else { $ArtifactName.Trim() })",
        "- GitHub Run Id: $(if ([string]::IsNullOrWhiteSpace($RunId)) { 'not-recorded-yet' } else { $RunId.Trim() })",
        "- Imported Handoff Count: $($importedSummaryPaths.Count)",
        "",
        "## Imported Summaries"
    )

    foreach ($path in $importedSummaryPaths) {
        $summaryLines += "- $path"
    }

    $summaryLines += @(
        "",
        "## Next Step",
        '- reuse the imported run label when starting `start-vm-test-cycle.ps1`',
        "- use this artifact-import summary as the bridge between GitHub Actions run output and local VM validation"
    )

    Set-Content -Path $summaryPath -Value $summaryLines -Encoding UTF8
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($cleanupPath) -and (Test-Path $cleanupPath)) {
        Remove-Item -LiteralPath $cleanupPath -Recurse -Force
    }
}

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Imported Lumina-OS GitHub Actions artifact:"
    Write-Host "Summary: $summaryPath"
}
