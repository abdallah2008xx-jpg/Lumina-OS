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
$cycleChainAuditScript = Join-Path $PSScriptRoot "audit-cycle-chain.ps1"
$releaseCandidateScript = Join-Path $PSScriptRoot "prepare-release-candidate.ps1"
$releaseValidator = Join-Path $PSScriptRoot "validate-release-package.ps1"

if (-not (Test-Path $handoffScript)) {
    throw "Missing smoke-test target: $handoffScript"
}

if (-not (Test-Path $cycleChainAuditScript)) {
    throw "Missing smoke-test target: $cycleChainAuditScript"
}

if (-not (Test-Path $releaseCandidateScript)) {
    throw "Missing smoke-test target: $releaseCandidateScript"
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
    $smokeRunLabel = "ci-release-smoke"
    $isoPath = Join-Path $tempRoot "lumina-smoke.iso"
    $notesPath = Join-Path $tempRoot "release-notes.md"
    $checksumPath = Join-Path $tempRoot "SHA256SUMS.txt"
    $buildPath = Join-Path $tempRoot "build-manifest.md"
    $vmPath = Join-Path $tempRoot "vm-report.md"
    $sessionPath = Join-Path $tempRoot "session-summary.md"
    $auditPath = Join-Path $tempRoot "session-audit.md"
    $blockersPath = Join-Path $tempRoot "blocker-review.md"
    $readinessPath = Join-Path $tempRoot "CURRENT-READINESS.md"
    $validationPath = Join-Path $tempRoot "CURRENT-VALIDATION-MATRIX.md"

    Set-Content -Path $isoPath -Value "lumina-smoke-iso" -Encoding ASCII
    $isoHash = (Get-FileHash -Algorithm SHA256 -Path $isoPath).Hash.ToLowerInvariant()
    Set-Content -Path $checksumPath -Value "$isoHash *lumina-smoke.iso" -Encoding ASCII
    Set-Content -Path $notesPath -Value "# Lumina Smoke Notes" -Encoding UTF8
    Set-Content -Path $buildPath -Value "# Build`r`n`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel`r`n- Full Path: $isoPath" -Encoding UTF8
    Set-Content -Path $vmPath -Value "# VM`r`n`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel" -Encoding UTF8
    Set-Content -Path $sessionPath -Value "# Session`r`n`r`n- Date: 2026-04-01`r`n- Mode: stable`r`n- Run Label: $smokeRunLabel`r`n- Build Manifest: $buildPath`r`n- VM Report: $vmPath" -Encoding UTF8
    Set-Content -Path $auditPath -Value "# Audit`r`n`r`n- Overall Status: pass`r`n- Run Label: $smokeRunLabel`r`n- Session Path: $sessionPath" -Encoding UTF8
    Set-Content -Path $blockersPath -Value "# Blockers`r`n`r`n- Run Label: $smokeRunLabel`r`n- Overall State: clear`r`n- Session Path: $sessionPath`r`n- VM Report Path: $vmPath`r`n- Audit Path: $auditPath" -Encoding UTF8
    Set-Content -Path $readinessPath -Value "# Readiness`r`n`r`n- Run Label: $smokeRunLabel`r`n- Readiness State: ready-for-next-stage`r`n- Mode: stable`r`n- Build Manifest: $buildPath`r`n- Session Summary: $sessionPath`r`n- Session Audit: $auditPath`r`n- Blocker Source: $blockersPath" -Encoding UTF8
    Set-Content -Path $validationPath -Value "# Validation`r`n`r`n- Overall State: ready-for-next-stage`r`n`r`n## Mode Summary`r`n- stable: ready-for-next-stage" -Encoding UTF8

    $cycleChainAuditPath = & $cycleChainAuditScript `
        -BuildManifestPath $buildPath `
        -VmReportPath $vmPath `
        -SessionPath $sessionPath `
        -AuditPath $auditPath `
        -BlockerPath $blockersPath `
        -ReadinessPath $readinessPath `
        -ValidationMatrixPath $validationPath `
        -RunLabel $smokeRunLabel `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $cycleChainAuditPath) -Message "Cycle chain audit report was not created."

    $cycleChainContent = Get-Content -Raw $cycleChainAuditPath
    Assert-Condition -Condition ($cycleChainContent -match [regex]::Escape("- Overall Status: pass")) -Message "Cycle chain audit did not pass."
    Assert-Condition -Condition ($cycleChainContent -match [regex]::Escape("- Run Label: $smokeRunLabel")) -Message "Cycle chain audit does not contain the expected run label."

    $candidateSummaryPath = & $releaseCandidateScript `
        -Version "0.1.0-ci" `
        -Mode stable `
        -RunLabel $smokeRunLabel `
        -IsoPath $isoPath `
        -BuildManifestPath $buildPath `
        -VmReportPath $vmPath `
        -SessionPath $sessionPath `
        -AuditPath $auditPath `
        -CycleChainAuditPath $cycleChainAuditPath `
        -ReadinessPath $readinessPath `
        -ValidationMatrixPath $validationPath `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $candidateSummaryPath) -Message "Release candidate summary was not created."

    $candidateContent = Get-Content -Raw $candidateSummaryPath
    Assert-Condition -Condition ($candidateContent -match [regex]::Escape("- Candidate State: ready-to-publish")) -Message "Release candidate summary is not ready-to-publish."
    Assert-Condition -Condition ($candidateContent -match [regex]::Escape("- Run Label: $smokeRunLabel")) -Message "Release candidate summary does not contain the expected run label."

    $releaseManifestPath = Get-ChildItem -Path $tempRoot -Filter "release-manifest.md" -Recurse | Select-Object -First 1 | ForEach-Object { $_.FullName }
    $validationReportPath = Get-ChildItem -Path $tempRoot -Filter "release-validation.md" -Recurse | Select-Object -First 1 | ForEach-Object { $_.FullName }

    Assert-Condition -Condition (-not [string]::IsNullOrWhiteSpace($releaseManifestPath) -and (Test-Path $releaseManifestPath)) -Message "Release manifest was not created by release candidate prep."
    Assert-Condition -Condition (-not [string]::IsNullOrWhiteSpace($validationReportPath) -and (Test-Path $validationReportPath)) -Message "Release validation report was not created by release candidate prep."

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
