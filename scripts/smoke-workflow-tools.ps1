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
$startCycleScript = Join-Path $PSScriptRoot "start-vm-test-cycle.ps1"
$buildManifestImportScript = Join-Path $PSScriptRoot "import-build-manifest.ps1"
$buildHandoffImportScript = Join-Path $PSScriptRoot "import-build-handoff.ps1"
$githubArtifactImportScript = Join-Path $PSScriptRoot "import-github-actions-artifact.ps1"
$githubArtifactDownloadScript = Join-Path $PSScriptRoot "download-github-actions-artifact.ps1"
$isoImportScript = Join-Path $PSScriptRoot "import-iso-artifact.ps1"
$githubArtifactCycleScript = Join-Path $PSScriptRoot "start-github-actions-vm-cycle.ps1"
$githubArtifactCycleFinishScript = Join-Path $PSScriptRoot "finish-github-actions-vm-cycle.ps1"
$prepareReleasePackageScript = Join-Path $PSScriptRoot "prepare-release-package.ps1"
$cycleChainAuditScript = Join-Path $PSScriptRoot "audit-cycle-chain.ps1"
$releaseCandidateScript = Join-Path $PSScriptRoot "prepare-release-candidate.ps1"
$syncReleaseCandidateScript = Join-Path $PSScriptRoot "sync-release-candidate-status.ps1"
$releaseContextScript = Join-Path $PSScriptRoot "validate-github-release-context.ps1"
$shareableUpdateScript = Join-Path $PSScriptRoot "sync-shareable-update.ps1"
$shareableBriefsScript = Join-Path $PSScriptRoot "sync-shareable-briefs.ps1"
$releaseValidator = Join-Path $PSScriptRoot "validate-release-package.ps1"

if (-not (Test-Path $handoffScript)) {
    throw "Missing smoke-test target: $handoffScript"
}

if (-not (Test-Path $startCycleScript)) {
    throw "Missing smoke-test target: $startCycleScript"
}

if (-not (Test-Path $buildManifestImportScript)) {
    throw "Missing smoke-test target: $buildManifestImportScript"
}

if (-not (Test-Path $buildHandoffImportScript)) {
    throw "Missing smoke-test target: $buildHandoffImportScript"
}

if (-not (Test-Path $githubArtifactImportScript)) {
    throw "Missing smoke-test target: $githubArtifactImportScript"
}

if (-not (Test-Path $githubArtifactDownloadScript)) {
    throw "Missing smoke-test target: $githubArtifactDownloadScript"
}

if (-not (Test-Path $isoImportScript)) {
    throw "Missing smoke-test target: $isoImportScript"
}

if (-not (Test-Path $githubArtifactCycleScript)) {
    throw "Missing smoke-test target: $githubArtifactCycleScript"
}

if (-not (Test-Path $githubArtifactCycleFinishScript)) {
    throw "Missing smoke-test target: $githubArtifactCycleFinishScript"
}

if (-not (Test-Path $prepareReleasePackageScript)) {
    throw "Missing smoke-test target: $prepareReleasePackageScript"
}

if (-not (Test-Path $cycleChainAuditScript)) {
    throw "Missing smoke-test target: $cycleChainAuditScript"
}

if (-not (Test-Path $releaseCandidateScript)) {
    throw "Missing smoke-test target: $releaseCandidateScript"
}

if (-not (Test-Path $syncReleaseCandidateScript)) {
    throw "Missing smoke-test target: $syncReleaseCandidateScript"
}

if (-not (Test-Path $releaseContextScript)) {
    throw "Missing smoke-test target: $releaseContextScript"
}

if (-not (Test-Path $shareableUpdateScript)) {
    throw "Missing smoke-test target: $shareableUpdateScript"
}

if (-not (Test-Path $shareableBriefsScript)) {
    throw "Missing smoke-test target: $shareableBriefsScript"
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
    $startCycleRunLabel = "ci-imported-build-smoke"
    $isoPath = Join-Path $tempRoot "lumina-smoke.iso"
    $notesPath = Join-Path $tempRoot "release-notes.md"
    $checksumPath = Join-Path $tempRoot "SHA256SUMS.txt"
    $buildPath = Join-Path $tempRoot "build-manifest.md"
    $externalBuildPath = Join-Path $tempRoot "external-build-manifest.md"
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
    Set-Content -Path $externalBuildPath -Value "# Build`r`n`r`n- Built At: 2026-04-01T11:20:00`r`n- Mode: stable`r`n- Run Label: $startCycleRunLabel`r`n- Full Path: /var/tmp/lumina-smoke.iso" -Encoding UTF8
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

    $importedBuildPath = (
        & $buildManifestImportScript `
            -ManifestPath $externalBuildPath `
            -Label $startCycleRunLabel `
            -RepoRoot $tempRoot `
            -OutputPathOnly |
        Select-Object -Last 1
    ).ToString().Trim()

    Assert-Condition -Condition (Test-Path $importedBuildPath) -Message "Imported build manifest was not created."
    $importedBuildContent = Get-Content -Raw $importedBuildPath
    Assert-Condition -Condition ($importedBuildContent -match [regex]::Escape("- Run Label: $startCycleRunLabel")) -Message "Imported build manifest does not contain the expected run label."

    $staleDiagnosticsDir = Join-Path $tempRoot "status\diagnostics\2026-04-01\stale-other-run"
    New-Item -ItemType Directory -Force -Path $staleDiagnosticsDir | Out-Null
    Set-Content -Path (Join-Path $staleDiagnosticsDir "import-manifest.md") -Value "# Import`r`n`r`n- Run Label: stale-other-run" -Encoding UTF8

    $startedSessionPath = & $startCycleScript `
        -Mode stable `
        -VmType VirtualBox `
        -Firmware UEFI `
        -IsoPath $isoPath `
        -BuildManifestPath $externalBuildPath `
        -RunLabel $startCycleRunLabel `
        -RepoRoot $tempRoot

    $startedSessionFile = Get-ChildItem -Path (Join-Path $tempRoot "status\test-sessions") -Filter "*.md" -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    Assert-Condition -Condition ($null -ne $startedSessionFile) -Message "VM cycle start did not create a session summary for the imported build path."
    $startedSessionContent = Get-Content -Raw $startedSessionFile.FullName
    Assert-Condition -Condition ($startedSessionContent -match [regex]::Escape("- Run Label: $startCycleRunLabel")) -Message "Started session does not contain the imported-build run label."
    Assert-Condition -Condition ($startedSessionContent -match [regex]::Escape("- Build Manifest: $importedBuildPath")) -Message "Started session did not record the imported build manifest path."
    Assert-Condition -Condition ($startedSessionContent -match [regex]::Escape("- Diagnostics Import: not-recorded-yet")) -Message "Started session reused a diagnostics import that did not match the current run label."

    $handoffRunLabel = "ci-build-handoff-smoke"
    $handoffDir = Join-Path $tempRoot "arch-build-handoff"
    New-Item -ItemType Directory -Force -Path $handoffDir | Out-Null
    Set-Content -Path (Join-Path $handoffDir "build-manifest.md") -Value "# Build`r`n`r`n- Built At: 2026-04-01T11:55:00`r`n- Mode: stable`r`n- Run Label: $handoffRunLabel`r`n- Full Path: /var/tmp/lumina-handoff.iso" -Encoding UTF8
    Copy-Item -LiteralPath $isoPath -Destination (Join-Path $handoffDir "lumina-handoff.iso") -Force
    Set-Content -Path (Join-Path $handoffDir "handoff-manifest.md") -Value "# Handoff`r`n`r`n- Mode: stable`r`n- Run Label: $handoffRunLabel" -Encoding UTF8

    $handoffImportSummary = & $buildHandoffImportScript `
        -HandoffPath $handoffDir `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $handoffImportSummary) -Message "Build handoff import summary was not created."
    $handoffImportContent = Get-Content -Raw $handoffImportSummary
    Assert-Condition -Condition ($handoffImportContent -match [regex]::Escape("- Reported Run Label: $handoffRunLabel")) -Message "Build handoff import did not record the reported run label."
    Assert-Condition -Condition ($handoffImportContent -match [regex]::Escape("- Imported ISO Path:")) -Message "Build handoff import did not record an imported ISO path."

    $artifactRoot = Join-Path $tempRoot "gha-artifact"
    $artifactPayloadRoot = Join-Path $artifactRoot "build\github-handoff\stable"
    $artifactPayloadDir = Join-Path $artifactPayloadRoot "handoff-folder"
    New-Item -ItemType Directory -Force -Path $artifactPayloadDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $handoffDir "handoff-manifest.md") -Destination (Join-Path $artifactPayloadDir "handoff-manifest.md") -Force
    Copy-Item -LiteralPath (Join-Path $handoffDir "build-manifest.md") -Destination (Join-Path $artifactPayloadDir "build-manifest.md") -Force
    Copy-Item -LiteralPath (Join-Path $handoffDir "lumina-handoff.iso") -Destination (Join-Path $artifactPayloadDir "lumina-handoff.iso") -Force

    $artifactZipPath = Join-Path $tempRoot "lumina-gha-artifact.zip"
    Compress-Archive -Path (Join-Path $artifactRoot "*") -DestinationPath $artifactZipPath -Force

    $diagnosticsBundleDir = Join-Path $tempRoot "diagnostics-bundle"
    New-Item -ItemType Directory -Force -Path $diagnosticsBundleDir | Out-Null
    Set-Content -Path (Join-Path $diagnosticsBundleDir "summary.md") -Value "# Summary`r`n`r`n- Exported At: 2026-04-01T12:00:00" -Encoding UTF8
    Set-Content -Path (Join-Path $diagnosticsBundleDir "firstboot-report.md") -Value "# Firstboot`r`n`r`n- Result: pass" -Encoding UTF8
    Set-Content -Path (Join-Path $diagnosticsBundleDir "smoke-check-report.md") -Value "# Smoke`r`n`r`n- Result: pass" -Encoding UTF8

    $artifactImportSummary = & $githubArtifactImportScript `
        -ArtifactPath $artifactZipPath `
        -ArtifactName "lumina-os-stable-gha-stable-8-1" `
        -RunId "23863815968" `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $artifactImportSummary) -Message "GitHub Actions artifact import summary was not created."
    $artifactImportContent = Get-Content -Raw $artifactImportSummary
    Assert-Condition -Condition ($artifactImportContent -match [regex]::Escape("- GitHub Run Id: 23863815968")) -Message "GitHub Actions artifact import did not record the expected run id."
    Assert-Condition -Condition ($artifactImportContent -match [regex]::Escape("- Imported Handoff Count: 1")) -Message "GitHub Actions artifact import did not record the expected handoff count."

    [void][scriptblock]::Create((Get-Content -Raw $githubArtifactDownloadScript))

    & $githubArtifactCycleScript `
        -ArtifactPath $artifactZipPath `
        -Mode stable `
        -VmType VirtualBox `
        -Firmware UEFI `
        -RunId "23863815968" `
        -ArtifactName "lumina-os-stable-gha-stable-8-1" `
        -RepoRoot $tempRoot | Out-Null

    $ghaStartedSessionFile = Get-ChildItem -Path (Join-Path $tempRoot "status\test-sessions") -Filter "*.md" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $ghaStartedSessionFile) -Message "GitHub Actions artifact cycle did not create a session summary."
    $ghaStartedSessionContent = Get-Content -Raw $ghaStartedSessionFile.FullName
    Assert-Condition -Condition ($ghaStartedSessionContent -match [regex]::Escape("- Run Label: $handoffRunLabel")) -Message "GitHub Actions artifact cycle did not reuse the reported run label."

    & $githubArtifactCycleFinishScript `
        -BundlePath $diagnosticsBundleDir `
        -ArtifactPath $artifactZipPath `
        -Mode stable `
        -VmType VirtualBox `
        -Firmware UEFI `
        -RunId "23863815968" `
        -ArtifactName "lumina-os-stable-gha-stable-8-1" `
        -RepoRoot $tempRoot | Out-Null

    $ghaFinishedSessionFile = Get-ChildItem -Path (Join-Path $tempRoot "status\test-sessions") -Filter "*.md" -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    Assert-Condition -Condition ($null -ne $ghaFinishedSessionFile) -Message "GitHub Actions cycle finish did not keep a session summary."
    $ghaFinishedSessionContent = Get-Content -Raw $ghaFinishedSessionFile.FullName
    Assert-Condition -Condition ($ghaFinishedSessionContent -match [regex]::Escape("- Diagnostics Bundle: $diagnosticsBundleDir")) -Message "GitHub Actions cycle finish did not record the diagnostics bundle path."

    $ghaAuditFile = Get-ChildItem -Path (Join-Path $tempRoot "status\test-session-audits") -Filter "*.md" -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    Assert-Condition -Condition ($null -ne $ghaAuditFile) -Message "GitHub Actions cycle finish did not create a session audit."
    $ghaAuditContent = Get-Content -Raw $ghaAuditFile.FullName
    Assert-Condition -Condition ($ghaAuditContent -match [regex]::Escape("- Run Label: $handoffRunLabel")) -Message "GitHub Actions cycle finish did not carry the expected run label into the session audit."

    $linuxOnlyBuildRunLabel = "ci-imported-iso-smoke"
    $linuxOnlyBuildPath = Join-Path $tempRoot "linux-only-build-manifest.md"
    Set-Content -Path $linuxOnlyBuildPath -Value "# Build`r`n`r`n- Built At: 2026-04-01T11:40:00`r`n- Mode: stable`r`n- Run Label: $linuxOnlyBuildRunLabel`r`n- Full Path: /var/tmp/lumina-from-arch.iso" -Encoding UTF8

    $importedIsoPath = & $isoImportScript `
        -IsoPath $isoPath `
        -Mode stable `
        -RunLabel $linuxOnlyBuildRunLabel `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $importedIsoPath) -Message "Imported ISO artifact was not created."

    $releasePackageManifestPath = & $prepareReleasePackageScript `
        -Version "0.1.0-ci-imported-iso" `
        -Mode stable `
        -RunLabel $linuxOnlyBuildRunLabel `
        -BuildManifestPath $linuxOnlyBuildPath `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $releasePackageManifestPath) -Message "Release manifest was not created from an imported ISO artifact."
    $importedIsoReleaseContent = Get-Content -Raw $releasePackageManifestPath
    Assert-Condition -Condition ($importedIsoReleaseContent -match [regex]::Escape("- ISO Path: $importedIsoPath")) -Message "Release manifest did not resolve the imported ISO path."

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

    $contextReportPath = & $releaseContextScript `
        -ReleaseManifestPath $releaseManifestPath `
        -Owner "abdallah2008xx-jpg" `
        -Repo "Lumina-OS" `
        -Token "ci-fake-token" `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $contextReportPath) -Message "GitHub release context report was not created."
    $contextContent = Get-Content -Raw $contextReportPath
    Assert-Condition -Condition ($contextContent -match [regex]::Escape("- Overall State: pass")) -Message "GitHub release context did not pass."
    Assert-Condition -Condition ($contextContent -match [regex]::Escape("- GitHub Repository: abdallah2008xx-jpg/Lumina-OS")) -Message "GitHub release context report does not contain the expected repository."

    $publishRecordPath = Join-Path (Split-Path -Parent $releaseManifestPath) "github-release-publish.md"
    Set-Content -Path $publishRecordPath -Value "# Publish`r`n`r`n- Run Label: $smokeRunLabel`r`n- Release URL: https://example.com/releases/v0.1.0-ci`r`n- Release ID: 12345" -Encoding UTF8

    $publishedCandidateSummaryPath = & $syncReleaseCandidateScript `
        -ReleaseManifestPath $releaseManifestPath `
        -ValidationReportPath $validationReportPath `
        -PublishRecordPath $publishRecordPath `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $publishedCandidateSummaryPath) -Message "Published release candidate summary was not created."
    $publishedCandidateContent = Get-Content -Raw $publishedCandidateSummaryPath
    Assert-Condition -Condition ($publishedCandidateContent -match [regex]::Escape("- Candidate State: published")) -Message "Release candidate summary did not switch to published."
    Assert-Condition -Condition ($publishedCandidateContent -match [regex]::Escape("- Release URL: https://example.com/releases/v0.1.0-ci")) -Message "Published release candidate summary does not expose the release URL."

    $statusDir = Join-Path $tempRoot "status"
    New-Item -ItemType Directory -Force -Path $statusDir | Out-Null
    Set-Content -Path (Join-Path $statusDir "CURRENT-STATUS.md") -Value @"
# Current Status

## Completed
- build/test workflow is structured
- release candidate workflow is structured
- publish context gate exists

## Next
- run the first real stable build in Arch
- run the first real VM cycle
- prepare the first real release candidate
"@ -Encoding UTF8

    $shareableUpdatePath = & $shareableUpdateScript `
        -StatusPath (Join-Path $statusDir "CURRENT-STATUS.md") `
        -ReadinessPath $readinessPath `
        -ValidationMatrixPath $validationPath `
        -ReleaseCandidatePath (Join-Path $tempRoot "status\\release-candidates\\CURRENT-RELEASE-CANDIDATE.md") `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $shareableUpdatePath) -Message "Shareable update snapshot was not created."
    $shareableContent = Get-Content -Raw $shareableUpdatePath
    Assert-Condition -Condition ($shareableContent -match [regex]::Escape("- Release Candidate State: published")) -Message "Shareable update did not include the published release-candidate state."
    Assert-Condition -Condition ($shareableContent -match [regex]::Escape("- run the first real stable build in Arch")) -Message "Shareable update did not include the expected next step."

    $shareableBriefPath = & $shareableBriefsScript `
        -ShareableUpdatePath (Join-Path $tempRoot "status\\SHAREABLE-UPDATE.md") `
        -ReleaseCandidatePath (Join-Path $tempRoot "status\\release-candidates\\CURRENT-RELEASE-CANDIDATE.md") `
        -RepoRoot $tempRoot `
        -OutputPathOnly

    Assert-Condition -Condition (Test-Path $shareableBriefPath) -Message "English shareable brief was not created."
    $shareableBriefContent = Get-Content -Raw $shareableBriefPath
    Assert-Condition -Condition ($shareableBriefContent -match [regex]::Escape("- Release Candidate State: published")) -Message "English shareable brief did not include the published release-candidate state."

    $shareableArabicBriefPath = Join-Path $tempRoot "status\\SHAREABLE-BRIEF-AR.md"
    Assert-Condition -Condition (Test-Path $shareableArabicBriefPath) -Message "Arabic shareable brief was not created."
    $shareableArabicBriefContent = Get-Content -Raw $shareableArabicBriefPath
    Assert-Condition -Condition ($shareableArabicBriefContent -match [regex]::Escape("- Release Candidate State: published")) -Message "Arabic shareable brief did not include the published release-candidate state."
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "Lumina-OS workflow smoke tests passed."
