param(
    [string]$ArtifactPath = "",
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$RunId = "",
    [string]$ArtifactName = "",
    [string]$Owner = "abdallah2008xx-jpg",
    [string]$Repo = "Lumina-OS",
    [string]$Token = "",
    [string]$RunLabel = "",
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

$artifactImportScript = Join-Path $PSScriptRoot "import-github-actions-artifact.ps1"
$artifactDownloadScript = Join-Path $PSScriptRoot "download-github-actions-artifact.ps1"
$startCycleScript = Join-Path $PSScriptRoot "start-vm-test-cycle.ps1"

if (-not (Test-Path $artifactImportScript)) {
    throw "Missing helper: $artifactImportScript"
}

if (-not (Test-Path $artifactDownloadScript)) {
    throw "Missing helper: $artifactDownloadScript"
}

if (-not (Test-Path $startCycleScript)) {
    throw "Missing helper: $startCycleScript"
}

$resolvedArtifactPath = $ArtifactPath
if ([string]::IsNullOrWhiteSpace($resolvedArtifactPath)) {
    if ([string]::IsNullOrWhiteSpace($RunId)) {
        throw "Provide -ArtifactPath, or provide -RunId so the GitHub Actions artifact can be downloaded automatically."
    }

    $resolvedArtifactPath = & $artifactDownloadScript `
        -RunId $RunId `
        -ArtifactName $ArtifactName `
        -Mode $Mode `
        -Owner $Owner `
        -Repo $Repo `
        -Token $Token `
        -RepoRoot $RepoRoot `
        -OutputPathOnly

    $resolvedArtifactPath = $resolvedArtifactPath.ToString().Trim()
}

$artifactImportSummaryPath = & $artifactImportScript `
    -ArtifactPath $resolvedArtifactPath `
    -RunId $RunId `
    -ArtifactName $ArtifactName `
    -Label $(if ([string]::IsNullOrWhiteSpace($RunLabel)) { "" } else { $RunLabel.Trim() }) `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$artifactImportSummaryPath = $artifactImportSummaryPath.ToString().Trim()

if (-not (Test-Path $artifactImportSummaryPath)) {
    throw "Artifact import summary was not created: $artifactImportSummaryPath"
}

$artifactImportSummary = Get-Content -Raw $artifactImportSummaryPath
$importedSummaryPaths = @(
    foreach ($line in ($artifactImportSummary -split "`r?`n")) {
        if ($line.Trim().StartsWith("- ")) {
            $candidate = $line.Trim().Substring(2).Trim()
            if ($candidate -like "*:\*") {
                $candidate
            }
        }
    }
)

if ($importedSummaryPaths.Count -eq 0) {
    throw "The GitHub Actions artifact import did not expose any imported handoff summaries."
}

$matchingImport = $null

foreach ($summaryPath in $importedSummaryPaths) {
    if (-not (Test-Path $summaryPath)) {
        continue
    }

    $summaryContent = Get-Content -Raw $summaryPath
    $reportedMode = Get-MetadataValue -Content $summaryContent -Label "Reported Mode"
    if ($reportedMode -eq $Mode) {
        $matchingImport = [PSCustomObject]@{
            SummaryPath = $summaryPath
            Content = $summaryContent
        }
        break
    }
}

if ($null -eq $matchingImport) {
    throw "Could not find an imported handoff summary for mode '$Mode' inside the artifact import."
}

$importedBuildManifestPath = Get-MetadataValue -Content $matchingImport.Content -Label "Imported Build Manifest"
$importedIsoPath = Get-MetadataValue -Content $matchingImport.Content -Label "Imported ISO Path"
$reportedRunLabel = Get-MetadataValue -Content $matchingImport.Content -Label "Reported Run Label"
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { $reportedRunLabel } else { $RunLabel.Trim() }

if ([string]::IsNullOrWhiteSpace($importedBuildManifestPath) -or -not (Test-Path $importedBuildManifestPath)) {
    throw "Imported build manifest path is missing or invalid: $importedBuildManifestPath"
}

if ([string]::IsNullOrWhiteSpace($importedIsoPath) -or -not (Test-Path $importedIsoPath)) {
    throw "Imported ISO path is missing or invalid: $importedIsoPath"
}

Write-Host "Imported GitHub Actions artifact for Lumina-OS."
Write-Host "Artifact Path:   $resolvedArtifactPath"
Write-Host "Import Summary: $artifactImportSummaryPath"
Write-Host "Mode:           $Mode"
Write-Host "Run Label:      $resolvedRunLabel"
Write-Host "Build Manifest: $importedBuildManifestPath"
Write-Host "ISO Path:       $importedIsoPath"
Write-Host ""

& $startCycleScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $importedIsoPath `
    -BuildManifestPath $importedBuildManifestPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot
