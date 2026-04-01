param(
    [string]$BuildManifestPath = "",
    [string]$SessionPath = "",
    [string]$AuditPath = "",
    [string]$BlockerPath = "",
    [string]$RunLabel = "",
    [switch]$OutputPathOnly,
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
        Where-Object { $_.Name -notin @("README.md", "CURRENT-BLOCKERS.md", "CURRENT-READINESS.md") } |
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
        Where-Object { $_.Name -notin @("README.md", "CURRENT-BLOCKERS.md", "CURRENT-READINESS.md") } |
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

function Get-ResolvedPathOrDefault {
    param(
        [string]$Value,
        [string]$DefaultValue
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $DefaultValue
    }

    return $Value
}

$resolvedBuildManifestPath = $BuildManifestPath
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath)) {
    $latestBuildManifest = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestFile -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\builds") -Filter "*.md" -RunLabel $RunLabel
    }
    if ($latestBuildManifest) {
        $resolvedBuildManifestPath = $latestBuildManifest.FullName
    }
}

$resolvedSessionPath = $SessionPath
if ([string]::IsNullOrWhiteSpace($resolvedSessionPath)) {
    $latestSession = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestFile -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-sessions") -Filter "*.md" -RunLabel $RunLabel
    }
    if ($latestSession) {
        $resolvedSessionPath = $latestSession.FullName
    }
}

$resolvedAuditPath = $AuditPath
if ([string]::IsNullOrWhiteSpace($resolvedAuditPath)) {
    $latestAudit = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestFile -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\test-session-audits") -Filter "*.md" -RunLabel $RunLabel
    }
    if ($latestAudit) {
        $resolvedAuditPath = $latestAudit.FullName
    }
}

$resolvedBlockerPath = $BlockerPath
if ([string]::IsNullOrWhiteSpace($resolvedBlockerPath)) {
    if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        $currentBlockerCandidate = Join-Path $RepoRoot "status\blockers\CURRENT-BLOCKERS.md"
        if (Test-Path $currentBlockerCandidate) {
            $resolvedBlockerPath = $currentBlockerCandidate
        }
    }
    else {
        $runLabelBlocker = Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\blockers") -Filter "*.md" -RunLabel $RunLabel
        if ($runLabelBlocker) {
            $resolvedBlockerPath = $runLabelBlocker.FullName
        }
    }
}

$buildContent = if (-not [string]::IsNullOrWhiteSpace($resolvedBuildManifestPath) -and (Test-Path $resolvedBuildManifestPath)) { Get-Content -Raw $resolvedBuildManifestPath } else { "" }
$sessionContent = if (-not [string]::IsNullOrWhiteSpace($resolvedSessionPath) -and (Test-Path $resolvedSessionPath)) { Get-Content -Raw $resolvedSessionPath } else { "" }
$auditContent = if (-not [string]::IsNullOrWhiteSpace($resolvedAuditPath) -and (Test-Path $resolvedAuditPath)) { Get-Content -Raw $resolvedAuditPath } else { "" }
$blockerContent = if (-not [string]::IsNullOrWhiteSpace($resolvedBlockerPath) -and (Test-Path $resolvedBlockerPath)) { Get-Content -Raw $resolvedBlockerPath } else { "" }

$sessionBuildManifestPath = Get-MetadataValue -Content $sessionContent -Label "Build Manifest"
if ([string]::IsNullOrWhiteSpace($resolvedBuildManifestPath) -and
    -not [string]::IsNullOrWhiteSpace($sessionBuildManifestPath) -and
    $sessionBuildManifestPath -ne "not-recorded-yet") {
    $resolvedBuildManifestPath = $sessionBuildManifestPath
    $buildContent = if (Test-Path $resolvedBuildManifestPath) { Get-Content -Raw $resolvedBuildManifestPath } else { "" }
}

$mode = Get-MetadataValue -Content $sessionContent -Label "Mode"
if ([string]::IsNullOrWhiteSpace($mode)) {
    $mode = Get-MetadataValue -Content $buildContent -Label "Mode"
}

$resolvedRunLabel = Get-MetadataValue -Content $sessionContent -Label "Run Label"
if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    $resolvedRunLabel = $RunLabel
}
$vmType = Get-MetadataValue -Content $sessionContent -Label "VM Type"
$dateLabel = Get-MetadataValue -Content $sessionContent -Label "Date"
if ([string]::IsNullOrWhiteSpace($dateLabel)) {
    $dateLabel = Get-Date -Format "yyyy-MM-dd"
}

$safeMode = if ([string]::IsNullOrWhiteSpace($mode)) { "unknown" } else { $mode.ToLowerInvariant() }
$safeVmType = if ([string]::IsNullOrWhiteSpace($vmType)) { "unknown" } else { $vmType.ToLowerInvariant().Replace(" ", "-") }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$snapshotSuffix = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "$stamp-$safeMode-$safeVmType" } else { $safeRunLabel }

$readinessDir = Join-Path $RepoRoot ("status\readiness\" + $dateLabel)
$snapshotPath = Join-Path $readinessDir ("readiness-" + $snapshotSuffix + ".md")
$currentReadinessPath = Join-Path $RepoRoot "status\readiness\CURRENT-READINESS.md"

New-Item -ItemType Directory -Force -Path $readinessDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentReadinessPath -Parent) | Out-Null

$buildState = "missing-build"
$isoFullPath = "not-recorded-yet"
$isoFile = "not-recorded-yet"
if (-not [string]::IsNullOrWhiteSpace($buildContent)) {
    $isoFullPath = Get-ResolvedPathOrDefault -Value (Get-MetadataValue -Content $buildContent -Label "Full Path") -DefaultValue "not-recorded-yet"
    $isoFile = Get-ResolvedPathOrDefault -Value (Get-MetadataValue -Content $buildContent -Label "File") -DefaultValue "not-recorded-yet"
    $buildState = if ($isoFullPath -in @("not-found", "not-recorded-yet", "")) { "manifest-without-iso" } else { "build-recorded" }
}

$auditState = Get-ResolvedPathOrDefault -Value (Get-MetadataValue -Content $auditContent -Label "Overall Status") -DefaultValue "not-recorded-yet"
$blockerState = Get-ResolvedPathOrDefault -Value (Get-MetadataValue -Content $blockerContent -Label "Overall State") -DefaultValue "not-recorded-yet"

$openBlockers = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "Open Blockers"))
$attentionItems = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $blockerContent -Heading "Attention Items"))

$sessionRecorded = -not [string]::IsNullOrWhiteSpace($resolvedSessionPath) -and (Test-Path $resolvedSessionPath)
$auditRecorded = -not [string]::IsNullOrWhiteSpace($resolvedAuditPath) -and (Test-Path $resolvedAuditPath)
$blockerRecorded = -not [string]::IsNullOrWhiteSpace($resolvedBlockerPath) -and (Test-Path $resolvedBlockerPath)

$readinessState = switch ($true) {
    { $buildState -eq "missing-build" } { "needs-build"; break }
    { $buildState -eq "manifest-without-iso" -and -not $sessionRecorded } { "needs-build-output"; break }
    { -not $sessionRecorded } { "needs-vm-cycle"; break }
    { -not $auditRecorded } { "needs-audit"; break }
    { -not $blockerRecorded } { "needs-blocker-sync"; break }
    { $blockerState -eq "blocked" } { "blocked"; break }
    { $buildState -eq "manifest-without-iso" } { "needs-build-output"; break }
    { $blockerState -eq "attention" -or $auditState -eq "warning" } { "attention"; break }
    { $auditState -eq "pass" -and $blockerState -eq "clear" } { "ready-for-next-stage"; break }
    default { "review-required" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
switch ($readinessState) {
    "needs-build" { $summaryItems.Add("No build manifest has been recorded yet.") }
    "needs-build-output" { $summaryItems.Add("A build manifest exists, but it does not point to a recorded ISO artifact.") }
    "needs-vm-cycle" { $summaryItems.Add("A build exists, but no linked VM cycle has been recorded yet.") }
    "needs-audit" { $summaryItems.Add("The VM cycle exists, but no audit report is linked yet.") }
    "needs-blocker-sync" { $summaryItems.Add("The audit exists, but the blocker register has not been synced yet.") }
    "blocked" { $summaryItems.Add("The latest cycle is blocked and should not be treated as ready.") }
    "attention" { $summaryItems.Add("The latest cycle has no hard blockers, but follow-up cleanup is still required.") }
    "ready-for-next-stage" { $summaryItems.Add("The latest recorded cycle has evidence, a passing audit, and no open blockers.") }
    default { $summaryItems.Add("The current evidence set needs a manual review.") }
}

$summaryItems.Add("Build state: $buildState")
$summaryItems.Add("Audit state: $auditState")
$summaryItems.Add("Blocker state: $blockerState")

$recommendation = switch ($readinessState) {
    "needs-build" { "- run the first real Arch build and generate a build manifest" }
    "needs-build-output" { "- inspect the build output path and confirm that the ISO artifact was produced" }
    "needs-vm-cycle" { "- boot the latest ISO and complete a VM cycle before moving on" }
    "needs-audit" { "- rerun or complete the audit step for the latest session" }
    "needs-blocker-sync" { "- sync blockers so the current cycle has a central state file" }
    "blocked" { "- fix the open blockers before promoting this cycle" }
    "attention" { "- clean up the remaining audit or evidence issues, then refresh readiness" }
    "ready-for-next-stage" { "- use this cycle as the current reference run for the next implementation step" }
    default { "- inspect the latest build, session, audit, and blocker files manually" }
}

$snapshotContent = @"
# Lumina-OS Readiness Snapshot

- Evaluated At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Readiness State: $readinessState
- Mode: $(if ([string]::IsNullOrWhiteSpace($mode)) { "unknown" } else { $mode })
- VM Type: $(if ([string]::IsNullOrWhiteSpace($vmType)) { "not-recorded-yet" } else { $vmType })

## Evidence Links
- Build Manifest: $(Get-ResolvedPathOrDefault -Value $resolvedBuildManifestPath -DefaultValue "not-recorded-yet")
- Session Summary: $(Get-ResolvedPathOrDefault -Value $resolvedSessionPath -DefaultValue "not-recorded-yet")
- Session Audit: $(Get-ResolvedPathOrDefault -Value $resolvedAuditPath -DefaultValue "not-recorded-yet")
- Blocker Source: $(Get-ResolvedPathOrDefault -Value $resolvedBlockerPath -DefaultValue "not-recorded-yet")

## Build Snapshot
- Build State: $buildState
- ISO File: $isoFile
- ISO Full Path: $isoFullPath

## Readiness Summary
$(Format-Items -Items $summaryItems)

## Open Blockers
$(Format-Items -Items $openBlockers)

## Attention Items
$(Format-Items -Items $attentionItems)

## Recommendation
$recommendation
"@

$currentContent = @"
# Lumina-OS Current Readiness

- Updated At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Readiness State: $readinessState
- Latest Snapshot: $snapshotPath
- Build Manifest: $(Get-ResolvedPathOrDefault -Value $resolvedBuildManifestPath -DefaultValue "not-recorded-yet")
- Session Summary: $(Get-ResolvedPathOrDefault -Value $resolvedSessionPath -DefaultValue "not-recorded-yet")
- Session Audit: $(Get-ResolvedPathOrDefault -Value $resolvedAuditPath -DefaultValue "not-recorded-yet")
- Blocker Source: $(Get-ResolvedPathOrDefault -Value $resolvedBlockerPath -DefaultValue "not-recorded-yet")

## Summary
$(Format-Items -Items $summaryItems)

## Open Blockers
$(Format-Items -Items $openBlockers)

## Attention Items
$(Format-Items -Items $attentionItems)

## Next Step
$recommendation
"@

Set-Content -Path $snapshotPath -Value $snapshotContent -Encoding UTF8
Set-Content -Path $currentReadinessPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $snapshotPath
}
else {
    Write-Host "Updated Lumina-OS readiness status:"
    Write-Host "Snapshot:          $snapshotPath"
    Write-Host "Current Readiness: $currentReadinessPath"
    Write-Host "State:             $readinessState"
}
