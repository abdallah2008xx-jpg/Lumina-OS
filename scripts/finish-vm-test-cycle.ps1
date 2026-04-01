param(
    [Parameter(Mandatory = $true)]
    [string]$BundlePath,
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$BuildManifestPath = "",
    [string]$VmReportPath = "",
    [string]$SessionPath = "",
    [string]$RunLabel = "",
    [string]$Label = "",
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

$importScript = Join-Path $PSScriptRoot "import-diagnostics-bundle.ps1"
$sessionScript = Join-Path $PSScriptRoot "new-test-session.ps1"
$auditScript = Join-Path $PSScriptRoot "audit-test-session.ps1"
$blockerScript = Join-Path $PSScriptRoot "sync-test-blockers.ps1"
$readinessScript = Join-Path $PSScriptRoot "sync-readiness-status.ps1"
$matrixScript = Join-Path $PSScriptRoot "sync-validation-matrix.ps1"

if (-not (Test-Path $importScript)) {
    throw "Missing helper: $importScript"
}

if (-not (Test-Path $sessionScript)) {
    throw "Missing helper: $sessionScript"
}

if (-not (Test-Path $auditScript)) {
    throw "Missing helper: $auditScript"
}

if (-not (Test-Path $blockerScript)) {
    throw "Missing helper: $blockerScript"
}

if (-not (Test-Path $readinessScript)) {
    throw "Missing helper: $readinessScript"
}

if (-not (Test-Path $matrixScript)) {
    throw "Missing helper: $matrixScript"
}

$resolvedBundlePath = (Resolve-Path $BundlePath).Path
$importLabel = if ([string]::IsNullOrWhiteSpace($Label)) { $RunLabel } else { $Label }
$diagnosticsImportPath = & $importScript -BundlePath $resolvedBundlePath -Label $importLabel -RepoRoot $RepoRoot -OutputPathOnly

if (-not $diagnosticsImportPath) {
    throw "Unable to import diagnostics bundle."
}

$targetSessionPath = $SessionPath
if ([string]::IsNullOrWhiteSpace($targetSessionPath)) {
    $latestSession = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md" -Mode $Mode
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md" -RunLabel $RunLabel
    }
    if ($latestSession) {
        $targetSessionPath = $latestSession.FullName
    }
}

$targetSessionContent = if (-not [string]::IsNullOrWhiteSpace($targetSessionPath) -and (Test-Path $targetSessionPath)) { Get-Content -Raw $targetSessionPath } else { "" }
$sessionBuildManifestPath = Get-MetadataValue -Content $targetSessionContent -Label "Build Manifest"
$sessionVmReportPath = Get-MetadataValue -Content $targetSessionContent -Label "VM Report"
$sessionRunLabel = Get-MetadataValue -Content $targetSessionContent -Label "Run Label"
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { $sessionRunLabel } else { $RunLabel.Trim() }

$resolvedBuildManifestPath = $BuildManifestPath
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
    if (-not [string]::IsNullOrWhiteSpace($sessionBuildManifestPath) -and $sessionBuildManifestPath -ne "not-recorded-yet") {
        $resolvedBuildManifestPath = $sessionBuildManifestPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
        $runLabelBuildManifest = Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -RunLabel $resolvedRunLabel
        $resolvedBuildManifestPath = if ($runLabelBuildManifest) { $runLabelBuildManifest.FullName } else { "" }
    }
    else {
        $latestBuildManifest = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode
        $resolvedBuildManifestPath = if ($latestBuildManifest) { $latestBuildManifest.FullName } else { "" }
    }
}

$resolvedVmReportPath = $VmReportPath
if ([string]::IsNullOrWhiteSpace($resolvedVmReportPath)) {
    if (-not [string]::IsNullOrWhiteSpace($sessionVmReportPath) -and $sessionVmReportPath -ne "not-recorded-yet") {
        $resolvedVmReportPath = $sessionVmReportPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
        $runLabelVmReport = Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -RunLabel $resolvedRunLabel
        $resolvedVmReportPath = if ($runLabelVmReport) { $runLabelVmReport.FullName } else { "" }
    }
    else {
        $latestVmReport = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -Mode $Mode
        $resolvedVmReportPath = if ($latestVmReport) { $latestVmReport.FullName } else { "" }
    }
}

$updatedSessionPath = & $sessionScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $IsoPath `
    -BuildManifestPath $resolvedBuildManifestPath `
    -VmReportPath $resolvedVmReportPath `
    -DiagnosticsBundlePath $resolvedBundlePath `
    -DiagnosticsImportPath $diagnosticsImportPath `
    -RunLabel $resolvedRunLabel `
    -SessionPath $targetSessionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if (-not $updatedSessionPath) {
    throw "Unable to update the test session summary."
}

$auditPath = & $auditScript -SessionPath $updatedSessionPath -RunLabel $resolvedRunLabel -RepoRoot $RepoRoot -OutputPathOnly

if (-not $auditPath) {
    throw "Unable to audit the updated test session summary."
}

$blockerReviewPath = & $blockerScript `
    -SessionPath $updatedSessionPath `
    -VmReportPath $resolvedVmReportPath `
    -AuditPath $auditPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if (-not $blockerReviewPath) {
    throw "Unable to sync the blocker register."
}

$readinessSnapshotPath = & $readinessScript `
    -BuildManifestPath $resolvedBuildManifestPath `
    -SessionPath $updatedSessionPath `
    -AuditPath $auditPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if (-not $readinessSnapshotPath) {
    throw "Unable to sync the readiness status."
}

$validationMatrixPath = & $matrixScript -RepoRoot $RepoRoot -OutputPathOnly

if (-not $validationMatrixPath) {
    throw "Unable to sync the validation matrix."
}

Write-Host "Finished Lumina-OS VM test cycle."
Write-Host "Run Label:         $resolvedRunLabel"
Write-Host "Diagnostics Import: $diagnosticsImportPath"
Write-Host "Session Summary:    $updatedSessionPath"
Write-Host "Session Audit:      $auditPath"
Write-Host "Blocker Review:     $blockerReviewPath"
Write-Host "Readiness Snapshot: $readinessSnapshotPath"
Write-Host "Validation Matrix:  $validationMatrixPath"
