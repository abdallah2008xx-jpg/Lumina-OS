param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$handoffScript = Join-Path $PSScriptRoot "new-cycle-handoff.ps1"
$releaseValidator = Join-Path $PSScriptRoot "validate-release-package.ps1"

if (-not (Test-Path $handoffScript)) {
    throw "Missing smoke-test target: $handoffScript"
}

if (-not (Test-Path $releaseValidator)) {
    throw "Missing smoke-test target: $releaseValidator"
}

foreach ($handoffCase in @(
    @{
        Mode = "stable"
        RunLabel = "ci-smoke-stable"
        ExpectedCommand = ".\scripts\build-iso.ps1 -Mode stable -RunLabel ci-smoke-stable"
        ExpectedModeText = "autologin reaches Plasma without stalling"
    },
    @{
        Mode = "login-test"
        RunLabel = "ci-smoke-login-test"
        ExpectedCommand = ".\scripts\build-iso.ps1 -Mode login-test -RunLabel ci-smoke-login-test"
        ExpectedModeText = "SDDM appears with the Lumina-OS theme applied"
    }
)) {
    $handoffPath = & $handoffScript `
        -Mode $handoffCase.Mode `
        -VmType VirtualBox `
        -Firmware UEFI `
        -RunLabel $handoffCase.RunLabel `
        -ReleaseVersion "0.1.0-ci" `
        -RepoRoot $RepoRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $handoffPath) -Message "Cycle handoff was not created for mode $($handoffCase.Mode)."
    $handoffContent = Get-Content -Raw $handoffPath
    Assert-Condition -Condition ($handoffContent -match [regex]::Escape("- Run Label: " + $handoffCase.RunLabel)) -Message "Cycle handoff does not contain the expected run label for mode $($handoffCase.Mode)."
    Assert-Condition -Condition ($handoffContent -match [regex]::Escape($handoffCase.ExpectedCommand)) -Message "Cycle handoff does not contain the expected build command for mode $($handoffCase.Mode)."
    Assert-Condition -Condition ($handoffContent -match [regex]::Escape($handoffCase.ExpectedModeText)) -Message "Cycle handoff does not contain the expected mode-specific checklist for mode $($handoffCase.Mode)."
    Remove-Item -LiteralPath $handoffPath -Force

    $handoffDir = Split-Path -Parent $handoffPath
    if ((Test-Path $handoffDir) -and -not (Get-ChildItem -Path $handoffDir -Force | Select-Object -First 1)) {
        Remove-Item -LiteralPath $handoffDir -Force
    }
}

$tempRoot = Join-Path $env:TEMP ("lumina-workflow-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    $isoPath = Join-Path $tempRoot "lumina-smoke.iso"
    $notesPath = Join-Path $tempRoot "release-notes.md"
    $checksumPath = Join-Path $tempRoot "SHA256SUMS.txt"
    $buildPath = Join-Path $tempRoot "build-manifest.md"
    $vmPath = Join-Path $tempRoot "vm-report.md"
    $sessionPath = Join-Path $tempRoot "session-summary.md"
    $auditPath = Join-Path $tempRoot "session-audit.md"
    $readinessPath = Join-Path $tempRoot "CURRENT-READINESS.md"
    $validationPath = Join-Path $tempRoot "CURRENT-VALIDATION-MATRIX.md"
    $blockersPath = Join-Path $tempRoot "CURRENT-BLOCKERS.md"
    $manifestPath = Join-Path $tempRoot "release-manifest.md"

    Set-Content -Path $isoPath -Value "lumina-smoke-iso" -Encoding ASCII
    $isoHash = (Get-FileHash -Algorithm SHA256 -Path $isoPath).Hash.ToLowerInvariant()
    Set-Content -Path $checksumPath -Value "$isoHash *lumina-smoke.iso" -Encoding ASCII
    Set-Content -Path $notesPath -Value "# Lumina Smoke Notes" -Encoding UTF8
    Set-Content -Path $buildPath -Value "# Build`r`n`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel" -Encoding UTF8
    Set-Content -Path $vmPath -Value "# VM`r`n`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel" -Encoding UTF8
    Set-Content -Path $sessionPath -Value "# Session`r`n`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel" -Encoding UTF8
    Set-Content -Path $auditPath -Value "# Audit`r`n`r`n- Audit State: passed`r`n- Run Label: $smokeRunLabel" -Encoding UTF8
    Set-Content -Path $blockersPath -Value "# Blockers`r`n`r`n- Overall State: clear" -Encoding UTF8
    Set-Content -Path $readinessPath -Value "# Readiness`r`n`r`n- Readiness State: ready-for-next-stage`r`n- Blocker Source: $blockersPath" -Encoding UTF8
    Set-Content -Path $validationPath -Value "# Validation`r`n`r`n- Overall State: ready-for-next-stage" -Encoding UTF8

    $manifestContent = @"
# Lumina-OS Release Manifest

- Version: 0.1.0-ci
- Mode: stable
- Run Label: $smokeRunLabel
- ISO Path: $isoPath
- Checksum File: $checksumPath
- Release Notes: $notesPath

## Evidence Links
- Build Manifest: $buildPath
- VM Report: $vmPath
- Session Summary: $sessionPath
- Session Audit: $auditPath
- Readiness: $readinessPath
- Validation Matrix: $validationPath
"@
    Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8

    $validationReportPath = & $releaseValidator -ReleaseManifestPath $manifestPath -RepoRoot $RepoRoot -OutputPathOnly
    Assert-Condition -Condition (Test-Path $validationReportPath) -Message "Release validation report was not created."

    $validationContent = Get-Content -Raw $validationReportPath
    Assert-Condition -Condition ($validationContent -match [regex]::Escape("- Result: passed")) -Message "Release validation report did not pass."
    Assert-Condition -Condition ($validationContent -match [regex]::Escape("- Run Label: $smokeRunLabel")) -Message "Release validation report does not contain the expected run label."
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "Lumina-OS workflow smoke tests passed."
