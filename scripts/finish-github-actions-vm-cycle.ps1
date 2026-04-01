param(
    [Parameter(Mandatory = $true)]
    [string]$BundlePath,
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
    [string]$IsoPath = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$SessionPath = "",
    [string]$RunLabel = "",
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

$artifactImportScript = Join-Path $PSScriptRoot "import-github-actions-artifact.ps1"
$artifactDownloadScript = Join-Path $PSScriptRoot "download-github-actions-artifact.ps1"
$finishCycleScript = Join-Path $PSScriptRoot "finish-vm-test-cycle.ps1"

if (-not (Test-Path $artifactImportScript)) {
    throw "Missing helper: $artifactImportScript"
}

if (-not (Test-Path $artifactDownloadScript)) {
    throw "Missing helper: $artifactDownloadScript"
}

if (-not (Test-Path $finishCycleScript)) {
    throw "Missing helper: $finishCycleScript"
}

$resolvedBuildManifestPath = $BuildManifestPath
$resolvedIsoPath = $IsoPath
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "" } else { $RunLabel.Trim() }
$resolvedArtifactPath = $ArtifactPath
$artifactImportSummaryPath = ""
$matchingImport = $null

$needsArtifactResolution = (
    -not [string]::IsNullOrWhiteSpace($resolvedArtifactPath) -or
    -not [string]::IsNullOrWhiteSpace($RunId) -or
    [string]::IsNullOrWhiteSpace($resolvedBuildManifestPath) -or
    [string]::IsNullOrWhiteSpace($resolvedIsoPath) -or
    [string]::IsNullOrWhiteSpace($resolvedRunLabel)
)

if ($needsArtifactResolution -and ([string]::IsNullOrWhiteSpace($resolvedArtifactPath) -and -not [string]::IsNullOrWhiteSpace($RunId))) {
    $resolvedArtifactPath = (
        & $artifactDownloadScript `
            -RunId $RunId `
            -ArtifactName $ArtifactName `
            -Mode $Mode `
            -Owner $Owner `
            -Repo $Repo `
            -Token $Token `
            -RepoRoot $RepoRoot `
            -OutputPathOnly |
        Select-Object -Last 1
    ).ToString().Trim()
}

if (-not [string]::IsNullOrWhiteSpace($resolvedArtifactPath)) {
    $artifactImportSummaryPath = (
        & $artifactImportScript `
            -ArtifactPath $resolvedArtifactPath `
            -RunId $RunId `
            -ArtifactName $ArtifactName `
            -Label $resolvedRunLabel `
            -RepoRoot $RepoRoot `
            -OutputPathOnly |
        Select-Object -Last 1
    ).ToString().Trim()

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
        throw "Could not find an imported handoff summary for mode '$Mode' inside the GitHub Actions artifact import."
    }

    if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
        $resolvedBuildManifestPath = Get-MetadataValue -Content $matchingImport.Content -Label "Imported Build Manifest"
    }

    if ([string]::IsNullOrWhiteSpace($resolvedIsoPath)) {
        $resolvedIsoPath = Get-MetadataValue -Content $matchingImport.Content -Label "Imported ISO Path"
    }

    if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
        $resolvedRunLabel = Get-MetadataValue -Content $matchingImport.Content -Label "Reported Run Label"
    }
}

if (-not [string]::IsNullOrWhiteSpace($resolvedBuildManifestPath) -and -not (Test-Path $resolvedBuildManifestPath)) {
    throw "Resolved build manifest path is missing or invalid: $resolvedBuildManifestPath"
}

if (-not [string]::IsNullOrWhiteSpace($resolvedIsoPath) -and -not (Test-Path $resolvedIsoPath)) {
    throw "Resolved ISO path is missing or invalid: $resolvedIsoPath"
}

if (-not [string]::IsNullOrWhiteSpace($artifactImportSummaryPath)) {
    Write-Host "Resolved Lumina-OS GitHub Actions context for cycle finish."
    Write-Host "Artifact Path:   $resolvedArtifactPath"
    Write-Host "Import Summary: $artifactImportSummaryPath"
    Write-Host "Mode:           $Mode"
    Write-Host "Run Label:      $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { 'not-resolved-yet' } else { $resolvedRunLabel })"
    Write-Host ""
}

& $finishCycleScript `
    -BundlePath $BundlePath `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $resolvedIsoPath `
    -BuildManifestPath $resolvedBuildManifestPath `
    -VmReportPath $VmReportPath `
    -SessionPath $SessionPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot
