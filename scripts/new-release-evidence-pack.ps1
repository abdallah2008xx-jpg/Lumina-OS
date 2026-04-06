param(
    [ValidateSet("stable", "login-test", "mixed", "unknown")]
    [string]$Mode = "stable",
    [ValidateSet("VirtualBox", "VMware", "QEMU", "Hyper-V", "Other")]
    [string]$VmType = "VirtualBox",
    [ValidateSet("BIOS", "UEFI")]
    [string]$Firmware = "UEFI",
    [string]$IsoPath = "",
    [string]$ReleaseVersion = "",
    [string]$DeviceLabel = "real-device",
    [string]$BootSource = "live-usb-or-installed-disk",
    [string]$RunLabel = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

$installScript = Join-Path $PSScriptRoot "new-install-test-report.ps1"
$loginTestScript = Join-Path $PSScriptRoot "new-login-test-report.ps1"
$hardwareScript = Join-Path $PSScriptRoot "new-hardware-test-report.ps1"
$runbookScript = Join-Path $PSScriptRoot "new-release-evidence-runbook.ps1"

foreach ($requiredScript in @($installScript, $loginTestScript, $hardwareScript, $runbookScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) { "$timeStamp-release-evidence" } else { $RunLabel.Trim() }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reportDir = Join-Path $RepoRoot ("status\evidence-packs\" + $dateStamp)
$reportPath = Join-Path $reportDir ("release-evidence-pack-$safeRunLabel.md")
$runbookPath = Join-Path $reportDir ("release-evidence-runbook-$safeRunLabel.md")

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$loginTestReportPath = & $loginTestScript `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $IsoPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$installReportPath = & $installScript `
    -Mode $Mode `
    -VmType $VmType `
    -Firmware $Firmware `
    -IsoPath $IsoPath `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$hardwareReportPath = & $hardwareScript `
    -DeviceLabel $DeviceLabel `
    -Firmware $Firmware `
    -BootSource $BootSource `
    -RunLabel $resolvedRunLabel `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$content = @"
# Lumina-OS Release Evidence Pack

- Created At: $(Get-Date -Format s)
- Run Label: $resolvedRunLabel
- Primary Mode: $Mode
- VM Type: $VmType
- Firmware: $Firmware
- ISO Path: $(if ([string]::IsNullOrWhiteSpace($IsoPath)) { "not-recorded-yet" } else { $IsoPath })
- Release Version: $(if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) { "not-recorded-yet" } else { $ReleaseVersion })
- Device Label: $DeviceLabel
- Boot Source: $BootSource
- Login-Test Report: $loginTestReportPath
- Install Report: $installReportPath
- Hardware Report: $hardwareReportPath
- Runbook Path: $runbookPath

## Purpose
- keep `login-test`, `install`, and `hardware` evidence on the same `Run Label`
- reduce release-prep drift before the final RC gate

## Next Step
- update these reports during the real run instead of creating separate unlabeled evidence later
- use the generated runbook to feed the same pack into release evidence audit and release candidate prep
"@

Set-Content -Path $reportPath -Value $content -Encoding UTF8

$runbookPath = & $runbookScript `
    -EvidencePackPath $reportPath `
    -ReleaseVersion $ReleaseVersion `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Created release evidence pack:"
    Write-Host $reportPath
}
