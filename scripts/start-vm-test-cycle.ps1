param(
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$BuildManifestPath = "",
    [string]$RunLabel = "",
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

$vmReportScript = Join-Path $PSScriptRoot "new-vm-test-report.ps1"
$sessionScript = Join-Path $PSScriptRoot "new-test-session.ps1"

if (-not (Test-Path $vmReportScript)) {
    throw "Missing helper: $vmReportScript"
}

if (-not (Test-Path $sessionScript)) {
    throw "Missing helper: $sessionScript"
}

$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeVmType = $VmType.ToLower().Replace(" ", "-")
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-$Mode-$safeVmType" } else { $RunLabel.Trim() }

$vmReportPath = & $vmReportScript -Mode $Mode -VmType $VmType -Firmware $Firmware -IsoPath $IsoPath -RunLabel $resolvedRunLabel -RepoRoot $RepoRoot -OutputPathOnly

if (-not $vmReportPath) {
    throw "Unable to create the VM test report."
}

$resolvedBuildManifestPath = $BuildManifestPath
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
    $latestBuildManifest = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
        Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode
    }
    else {
        $byRunLabel = Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -RunLabel $resolvedRunLabel
        if ($byRunLabel) { $byRunLabel } else { Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -Mode $Mode }
    }
    $resolvedBuildManifestPath = if ($latestBuildManifest) { $latestBuildManifest.FullName } else { "" }
}

$sessionPath = & $sessionScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $IsoPath `
    -BuildManifestPath $resolvedBuildManifestPath `
    -VmReportPath $vmReportPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if (-not $sessionPath) {
    throw "Unable to create the test session summary."
}

Write-Host "Started Lumina-OS VM test cycle."
Write-Host "Run Label:      $resolvedRunLabel"
Write-Host "VM Report:      $vmReportPath"
Write-Host "Session Summary: $sessionPath"
