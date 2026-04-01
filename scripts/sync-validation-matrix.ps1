param(
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-LatestModeFile {
    param(
        [string]$Path,
        [string]$Mode,
        [switch]$AllowMetadataModeMatch
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $escapedMode = [regex]::Escape($Mode)
    $pattern = "-" + $escapedMode + "([\\.-]|$)"

    return Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("README.md", "CURRENT-BLOCKERS.md", "CURRENT-READINESS.md", "CURRENT-VALIDATION-MATRIX.md") } |
        Where-Object {
            if ($_.Name -match $pattern) {
                return $true
            }

            if ($AllowMetadataModeMatch) {
                $content = Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue
                return ($content -match ("(?m)^- Mode: " + $escapedMode + "$"))
            }

            return $false
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

function Get-SectionContent {
    param(
        [string]$Content,
        [string]$Heading
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return ""
    }

    $pattern = "(?s)^## " + [regex]::Escape($Heading) + "\r?\n(?<body>.*?)(?=^## |\z)"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($match.Success) {
        return $match.Groups["body"].Value.Trim()
    }

    return ""
}

function Convert-SectionToItems {
    param([string]$SectionContent)

    $items = [System.Collections.Generic.List[string]]::new()
    $currentItem = ""

    foreach ($rawLine in ($SectionContent -split "`r?`n")) {
        $line = $rawLine.Trim()

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line.StartsWith("- ")) {
            if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
                $items.Add($currentItem)
            }

            $currentItem = $line.Substring(2).Trim()
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
            $currentItem += " | " + $line
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
        $items.Add($currentItem)
    }

    return $items
}

function Get-MeaningfulItems {
    param([System.Collections.Generic.List[string]]$Items)

    $result = [System.Collections.Generic.List[string]]::new()
    $placeholderPatterns = @(
        '^none yet$',
        '^none$',
        '^n/a$'
    )

    foreach ($item in $Items) {
        $trimmed = $item.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        $isPlaceholder = $false
        foreach ($pattern in $placeholderPatterns) {
            if ($trimmed -match $pattern) {
                $isPlaceholder = $true
                break
            }
        }

        if (-not $isPlaceholder) {
            $result.Add($trimmed)
        }
    }

    return $result
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
}

function Get-ModeSnapshot {
    param(
        [string]$Mode,
        [string]$RepoRoot
    )

    $buildFile = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\builds") -Mode $Mode -AllowMetadataModeMatch
    $sessionFile = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\test-sessions") -Mode $Mode -AllowMetadataModeMatch
    $auditFile = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\test-session-audits") -Mode $Mode -AllowMetadataModeMatch
    $blockerFile = Get-LatestModeFile -Path (Join-Path $RepoRoot "status\blockers") -Mode $Mode

    $buildContent = if ($buildFile) { Get-Content -Raw $buildFile.FullName } else { "" }
    $sessionContent = if ($sessionFile) { Get-Content -Raw $sessionFile.FullName } else { "" }
    $auditContent = if ($auditFile) { Get-Content -Raw $auditFile.FullName } else { "" }
    $blockerContent = if ($blockerFile) { Get-Content -Raw $blockerFile.FullName } else { "" }

    $buildState = "missing-build"
    $isoFile = "not-recorded-yet"
    $isoFullPath = "not-recorded-yet"

    if ($buildFile) {
        $isoFile = Get-MetadataValue -Content $buildContent -Label "File"
        if ([string]::IsNullOrWhiteSpace($isoFile)) {
            $isoFile = "not-recorded-yet"
        }

        $isoFullPath = Get-MetadataValue -Content $buildContent -Label "Full Path"
        if ([string]::IsNullOrWhiteSpace($isoFullPath)) {
            $isoFullPath = "not-recorded-yet"
        }

        $buildState = if ($isoFullPath -in @("not-found", "not-recorded-yet", "")) { "manifest-without-iso" } else { "build-recorded" }
    }

    $sessionRecorded = $null -ne $sessionFile
    $auditRecorded = $null -ne $auditFile
    $blockerRecorded = $null -ne $blockerFile

    $auditFailures = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "Audit Failures"))
    $sessionBlockers = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "Session Blockers"))
    $vmBlockers = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "VM Report Blockers"))
    $attentionItems = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "Audit Warnings"))

    $openBlockers = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $sessionBlockers) {
        $openBlockers.Add("[session] $item")
    }
    foreach ($item in $vmBlockers) {
        $openBlockers.Add("[vm] $item")
    }
    foreach ($item in $auditFailures) {
        $openBlockers.Add("[audit] $item")
    }

    $modeState = switch ($true) {
        { $buildState -eq "missing-build" } { "needs-build"; break }
        { $buildState -eq "manifest-without-iso" -and -not $sessionRecorded } { "needs-build-output"; break }
        { -not $sessionRecorded } { "needs-vm-cycle"; break }
        { -not $auditRecorded } { "needs-audit"; break }
        { -not $blockerRecorded } { "needs-blocker-review"; break }
        { $openBlockers.Count -gt 0 } { "blocked"; break }
        { $buildState -eq "manifest-without-iso" } { "needs-build-output"; break }
        { $attentionItems.Count -gt 0 } { "attention"; break }
        default { "ready-for-next-stage" }
    }

    $nextStep = switch ($modeState) {
        "needs-build" { "run the first $Mode Arch build" }
        "needs-build-output" { "confirm the ISO artifact recorded by the $Mode build manifest" }
        "needs-vm-cycle" { "boot the latest $Mode ISO and complete a VM cycle" }
        "needs-audit" { "generate or refresh the $Mode session audit" }
        "needs-blocker-review" { "generate the $Mode blocker review" }
        "blocked" { "fix the open $Mode blockers before continuing" }
        "attention" { "clean up the remaining $Mode warnings and refresh the reports" }
        default { "use the latest $Mode cycle as a reference run" }
    }

    return [pscustomobject]@{
        Mode = $Mode
        ModeState = $modeState
        BuildState = $buildState
        BuildManifestPath = if ($buildFile) { $buildFile.FullName } else { "not-recorded-yet" }
        SessionPath = if ($sessionFile) { $sessionFile.FullName } else { "not-recorded-yet" }
        AuditPath = if ($auditFile) { $auditFile.FullName } else { "not-recorded-yet" }
        BlockerReviewPath = if ($blockerFile) { $blockerFile.FullName } else { "not-recorded-yet" }
        IsoFile = $isoFile
        IsoFullPath = $isoFullPath
        OpenBlockers = $openBlockers
        AttentionItems = $attentionItems
        NextStep = $nextStep
    }
}

$modes = @("stable", "login-test")
$modeSnapshots = foreach ($mode in $modes) {
    Get-ModeSnapshot -Mode $mode -RepoRoot $RepoRoot
}

$readyCount = @($modeSnapshots | Where-Object { $_.ModeState -eq "ready-for-next-stage" }).Count
$blockedCount = @($modeSnapshots | Where-Object { $_.ModeState -eq "blocked" }).Count
$attentionCount = @($modeSnapshots | Where-Object { $_.ModeState -eq "attention" }).Count
$needsBuildCount = @($modeSnapshots | Where-Object { $_.ModeState -eq "needs-build" }).Count

$overallState = switch ($true) {
    { $readyCount -eq $modeSnapshots.Count } { "ready-both-modes"; break }
    { $blockedCount -gt 0 } { "blocked"; break }
    { $attentionCount -gt 0 } { "attention"; break }
    { $needsBuildCount -eq $modeSnapshots.Count } { "needs-first-build"; break }
    default { "in-progress" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Ready modes: $readyCount / $($modeSnapshots.Count)")
$summaryItems.Add("Blocked modes: $blockedCount")
$summaryItems.Add("Attention modes: $attentionCount")

$recommendation = switch ($overallState) {
    "ready-both-modes" { "- both modes have a usable reference cycle; the project can move to the next implementation stage" }
    "blocked" { "- at least one mode is blocked; fix that mode before treating the matrix as healthy" }
    "attention" { "- no hard blockers are open, but one or more modes still need cleanup" }
    "needs-first-build" { "- no real build has been recorded yet for either mode; start with the first Arch build" }
    default { "- continue filling the missing mode coverage until both `stable` and `login-test` have real evidence" }
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$matrixDir = Join-Path $RepoRoot ("status\validation-matrix\" + $dateStamp)
$snapshotPath = Join-Path $matrixDir ("validation-matrix-" + $timeStamp + ".md")
$currentMatrixPath = Join-Path $RepoRoot "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md"

New-Item -ItemType Directory -Force -Path $matrixDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentMatrixPath -Parent) | Out-Null

$modeSummaryLines = ($modeSnapshots | ForEach-Object {
    "- " + $_.Mode + ": " + $_.ModeState
}) -join "`r`n"

$modeDetailSections = ($modeSnapshots | ForEach-Object {
@"
## $($_.Mode)
- Mode State: $($_.ModeState)
- Build State: $($_.BuildState)
- Build Manifest: $($_.BuildManifestPath)
- Session Summary: $($_.SessionPath)
- Session Audit: $($_.AuditPath)
- Blocker Review: $($_.BlockerReviewPath)
- ISO File: $($_.IsoFile)
- ISO Full Path: $($_.IsoFullPath)

### Open Blockers
$(Format-Items -Items $_.OpenBlockers)

### Attention Items
$(Format-Items -Items $_.AttentionItems)

### Next Step
- $($_.NextStep)
"@
}) -join "`r`n`r`n"

$snapshotContent = @"
# AhmadOS Validation Matrix

- Evaluated At: $(Get-Date -Format s)
- Overall State: $overallState

## Mode Summary
$modeSummaryLines

## Global Summary
$(Format-Items -Items $summaryItems)

$modeDetailSections

## Recommendation
$recommendation
"@

$currentContent = @"
# AhmadOS Current Validation Matrix

- Updated At: $(Get-Date -Format s)
- Overall State: $overallState
- Latest Snapshot: $snapshotPath

## Mode Summary
$modeSummaryLines

## Global Summary
$(Format-Items -Items $summaryItems)

## Recommendation
$recommendation
"@

Set-Content -Path $snapshotPath -Value $snapshotContent -Encoding UTF8
Set-Content -Path $currentMatrixPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $snapshotPath
}
else {
    Write-Host "Updated AhmadOS validation matrix:"
    Write-Host "Snapshot: $snapshotPath"
    Write-Host "Current:  $currentMatrixPath"
    Write-Host "State:    $overallState"
}
