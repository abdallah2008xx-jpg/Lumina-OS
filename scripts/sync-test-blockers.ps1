param(
    [string]$SessionPath = "",
    [string]$VmReportPath = "",
    [string]$AuditPath = "",
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
        Where-Object { $_.Name -notin @("README.md", "CURRENT-BLOCKERS.md") } |
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
        Where-Object { $_.Name -notin @("README.md", "CURRENT-BLOCKERS.md") } |
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

$resolvedVmReportPath = $VmReportPath
if ([string]::IsNullOrWhiteSpace($resolvedVmReportPath)) {
    $latestVmReport = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
        Get-LatestFile -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md"
    }
    else {
        Get-FileByRunLabel -Path (Join-Path $RepoRoot "status\vm-tests") -Filter "*.md" -RunLabel $RunLabel
    }
    if ($latestVmReport) {
        $resolvedVmReportPath = $latestVmReport.FullName
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

if ([string]::IsNullOrWhiteSpace($resolvedSessionPath) -or -not (Test-Path $resolvedSessionPath)) {
    throw "Unable to find a session summary for blocker sync."
}

$sessionContent = Get-Content -Raw $resolvedSessionPath
$vmReportContent = if (-not [string]::IsNullOrWhiteSpace($resolvedVmReportPath) -and (Test-Path $resolvedVmReportPath)) { Get-Content -Raw $resolvedVmReportPath } else { "" }
$auditContent = if (-not [string]::IsNullOrWhiteSpace($resolvedAuditPath) -and (Test-Path $resolvedAuditPath)) { Get-Content -Raw $resolvedAuditPath } else { "" }

$mode = Get-MetadataValue -Content $sessionContent -Label "Mode"
$vmType = Get-MetadataValue -Content $sessionContent -Label "VM Type"
$sessionDate = Get-MetadataValue -Content $sessionContent -Label "Date"
$resolvedRunLabel = Get-MetadataValue -Content $sessionContent -Label "Run Label"
if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    $resolvedRunLabel = $RunLabel
}
$safeMode = if ([string]::IsNullOrWhiteSpace($mode)) { "unknown" } else { $mode.ToLowerInvariant() }
$safeVmType = if ([string]::IsNullOrWhiteSpace($vmType)) { "unknown" } else { $vmType.ToLowerInvariant().Replace(" ", "-") }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$reviewDate = if ([string]::IsNullOrWhiteSpace($sessionDate)) { Get-Date -Format "yyyy-MM-dd" } else { $sessionDate }
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$blockerDir = Join-Path $RepoRoot ("status\blockers\" + $reviewDate)
$reviewSuffix = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "$timeStamp-$safeMode-$safeVmType" } else { $safeRunLabel }
$reviewPath = Join-Path $blockerDir ("blocker-review-" + $reviewSuffix + ".md")
$currentBlockersPath = Join-Path $RepoRoot "status\blockers\CURRENT-BLOCKERS.md"

New-Item -ItemType Directory -Force -Path $blockerDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentBlockersPath -Parent) | Out-Null

$sessionBlockers = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $sessionContent -Heading "Blockers"))
$vmBlockers = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $vmReportContent -Heading "Blockers"))
$auditFailures = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $auditContent -Heading "Failures"))
$auditWarnings = Get-MeaningfulItems (Convert-SectionToItems -SectionContent (Get-SectionContent -Content $auditContent -Heading "Warnings"))

$hasOpenBlockers = ($sessionBlockers.Count + $vmBlockers.Count + $auditFailures.Count) -gt 0
$hasAttentionItems = $auditWarnings.Count -gt 0

$overallState = if ($hasOpenBlockers) {
    "blocked"
}
elseif ($hasAttentionItems) {
    "attention"
}
else {
    "clear"
}

$allOpenItems = [System.Collections.Generic.List[string]]::new()
foreach ($item in $sessionBlockers) {
    $allOpenItems.Add("[session] $item")
}
foreach ($item in $vmBlockers) {
    $allOpenItems.Add("[vm] $item")
}
foreach ($item in $auditFailures) {
    $allOpenItems.Add("[audit] $item")
}

$attentionItems = [System.Collections.Generic.List[string]]::new()
foreach ($item in $auditWarnings) {
    $attentionItems.Add("[audit-warning] $item")
}

$reviewContent = @"
# AhmadOS Blocker Review

- Reviewed At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Overall State: $overallState
- Session Path: $resolvedSessionPath
- VM Report Path: $(if ([string]::IsNullOrWhiteSpace($resolvedVmReportPath)) { "not-recorded-yet" } else { $resolvedVmReportPath })
- Audit Path: $(if ([string]::IsNullOrWhiteSpace($resolvedAuditPath)) { "not-recorded-yet" } else { $resolvedAuditPath })

## Session Blockers
$(Format-Items -Items $sessionBlockers)

## VM Report Blockers
$(Format-Items -Items $vmBlockers)

## Audit Failures
$(Format-Items -Items $auditFailures)

## Audit Warnings
$(Format-Items -Items $auditWarnings)

## Recommendation
$(switch ($overallState) {
    "blocked" { "- fix the recorded blockers before treating this cycle as ready" }
    "attention" { "- the cycle has no hard blockers, but the audit still needs cleanup before it is a clean reference run" }
    default { "- no blockers are currently recorded for this cycle" }
})
"@

$currentContent = @"
# AhmadOS Current Blockers

- Updated At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Overall State: $overallState
- Latest Review: $reviewPath
- Session Path: $resolvedSessionPath
- VM Report Path: $(if ([string]::IsNullOrWhiteSpace($resolvedVmReportPath)) { "not-recorded-yet" } else { $resolvedVmReportPath })
- Audit Path: $(if ([string]::IsNullOrWhiteSpace($resolvedAuditPath)) { "not-recorded-yet" } else { $resolvedAuditPath })

## Open Blockers
$(Format-Items -Items $allOpenItems)

## Attention Items
$(Format-Items -Items $attentionItems)

## Next Step
$(switch ($overallState) {
    "blocked" { "- use this file as the current blocker list while fixing the active cycle" }
    "attention" { "- resolve the remaining audit warnings or update the session files with final notes" }
    default { "- keep this file clear until the next real VM cycle introduces new blockers" }
})
"@

Set-Content -Path $reviewPath -Value $reviewContent -Encoding UTF8
Set-Content -Path $currentBlockersPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $reviewPath
}
else {
    Write-Host "Updated AhmadOS blocker register:"
    Write-Host "Review:          $reviewPath"
    Write-Host "Current Blockers: $currentBlockersPath"
    Write-Host "Overall state:   $overallState"
}
