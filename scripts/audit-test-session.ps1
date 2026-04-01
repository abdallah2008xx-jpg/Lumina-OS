param(
    [string]$SessionPath = "",
    [string]$RunLabel = "",
    [switch]$OutputPathOnly,
    [switch]$FailOnMissing,
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
        Where-Object { $_.Name -ne "README.md" } |
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
        Where-Object { $_.Name -ne "README.md" } |
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

function Get-PathAudit {
    param(
        [string]$Label,
        [string]$Value
    )

    $normalizedValue = if ([string]::IsNullOrWhiteSpace($Value)) { "" } else { $Value.Trim() }

    if ([string]::IsNullOrWhiteSpace($normalizedValue) -or $normalizedValue -in @("not-recorded-yet", "not-found")) {
        return [pscustomobject]@{
            Label = $Label
            Mark = " "
            Status = "missing"
            Value = if ([string]::IsNullOrWhiteSpace($normalizedValue)) { "not-recorded-yet" } else { $normalizedValue }
        }
    }

    if (Test-Path $normalizedValue) {
        return [pscustomobject]@{
            Label = $Label
            Mark = "x"
            Status = "present"
            Value = $normalizedValue
        }
    }

    return [pscustomobject]@{
        Label = $Label
        Mark = " "
        Status = "broken"
        Value = $normalizedValue
    }
}

function Add-ListItem {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        $Target.Add($Message)
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

if ([string]::IsNullOrWhiteSpace($resolvedSessionPath)) {
    throw "Unable to find a test session summary to audit."
}

if (-not (Test-Path $resolvedSessionPath)) {
    throw "Test session summary not found: $resolvedSessionPath"
}

$sessionContent = Get-Content -Raw $resolvedSessionPath
$resolvedRunLabel = Get-MetadataValue -Content $sessionContent -Label "Run Label"
if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) {
    $resolvedRunLabel = $RunLabel
}
$mode = Get-MetadataValue -Content $sessionContent -Label "Mode"
$vmType = Get-MetadataValue -Content $sessionContent -Label "VM Type"
$sessionDate = Get-MetadataValue -Content $sessionContent -Label "Date"
$safeMode = if ([string]::IsNullOrWhiteSpace($mode)) { "unknown" } else { $mode.ToLowerInvariant() }
$safeVmType = if ([string]::IsNullOrWhiteSpace($vmType)) { "unknown" } else { $vmType.ToLowerInvariant().Replace(" ", "-") }
$safeRunLabel = Get-SafeFileSegment $resolvedRunLabel
$auditDate = if ([string]::IsNullOrWhiteSpace($sessionDate)) { Get-Date -Format "yyyy-MM-dd" } else { $sessionDate }
$auditTimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$auditDir = Join-Path $RepoRoot ("status\test-session-audits\" + $auditDate)
$auditSuffix = if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "$auditTimeStamp-$safeMode-$safeVmType" } else { $safeRunLabel }
$auditPath = Join-Path $auditDir ("test-session-audit-" + $auditSuffix + ".md")

New-Item -ItemType Directory -Force -Path $auditDir | Out-Null

$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

$isoPath = Get-MetadataValue -Content $sessionContent -Label "ISO Path"
$buildManifestPath = Get-MetadataValue -Content $sessionContent -Label "Build Manifest"
$vmReportPath = Get-MetadataValue -Content $sessionContent -Label "VM Report"
$diagnosticsBundlePath = Get-MetadataValue -Content $sessionContent -Label "Diagnostics Bundle"
$diagnosticsImportPath = Get-MetadataValue -Content $sessionContent -Label "Diagnostics Import"

$evidenceChecks = @(
    (Get-PathAudit -Label "Build Manifest" -Value $buildManifestPath),
    (Get-PathAudit -Label "VM Report" -Value $vmReportPath),
    (Get-PathAudit -Label "Diagnostics Bundle" -Value $diagnosticsBundlePath),
    (Get-PathAudit -Label "Diagnostics Import" -Value $diagnosticsImportPath)
)

foreach ($check in $evidenceChecks) {
    if ($check.Status -ne "present") {
        Add-ListItem -Target $failures -Message ($check.Label + " is " + $check.Status + ": " + $check.Value)
    }
}

$importContent = ""
$importSourcePath = ""
$summaryPath = ""
$firstbootPath = ""
$smokePath = ""

if (Test-Path $diagnosticsImportPath) {
    $importContent = Get-Content -Raw $diagnosticsImportPath
    $importSourcePath = Get-MetadataValue -Content $importContent -Label "Source Path"
    $summaryPath = Get-MetadataValue -Content $importContent -Label "Summary"
    $firstbootPath = Get-MetadataValue -Content $importContent -Label "Firstboot Report"
    $smokePath = Get-MetadataValue -Content $importContent -Label "Smoke Check Report"
}

$importChecks = @(
    (Get-PathAudit -Label "Imported Summary" -Value $summaryPath),
    (Get-PathAudit -Label "Imported Firstboot Report" -Value $firstbootPath),
    (Get-PathAudit -Label "Imported Smoke Check Report" -Value $smokePath)
)

foreach ($check in $importChecks) {
    if ($check.Status -ne "present") {
        Add-ListItem -Target $warnings -Message ($check.Label + " is " + $check.Status + ": " + $check.Value)
    }
}

if (-not [string]::IsNullOrWhiteSpace($diagnosticsBundlePath) -and
    -not [string]::IsNullOrWhiteSpace($importSourcePath) -and
    $diagnosticsBundlePath -notin @("not-recorded-yet", "not-found") -and
    $importSourcePath -ne $diagnosticsBundlePath) {
    Add-ListItem -Target $warnings -Message ("Diagnostics bundle path does not match the import source path: " + $diagnosticsBundlePath + " <> " + $importSourcePath)
}

$decisionSummary = Get-SectionContent -Content $sessionContent -Heading "Decision Summary"
$notesSection = Get-SectionContent -Content $sessionContent -Heading "Notes"

if ($decisionSummary -match [regex]::Escape("continue / fix blockers / rebuild")) {
    Add-ListItem -Target $warnings -Message "Session decision summary still contains the default placeholder text."
}

if ($notesSection -match [regex]::Escape("link the exact diagnostics bundle path here")) {
    Add-ListItem -Target $warnings -Message "Session notes still contain the default placeholder guidance."
}

$vmReportContent = ""
if (Test-Path $vmReportPath) {
    $vmReportContent = Get-Content -Raw $vmReportPath
    $vmNotes = Get-SectionContent -Content $vmReportContent -Heading "Notes"
    if ($vmNotes -match [regex]::Escape("add firstboot-report observations here")) {
        Add-ListItem -Target $warnings -Message "VM report notes still contain the default placeholder guidance."
    }
}

$overallStatus = if ($failures.Count -gt 0) {
    "fail"
}
elseif ($warnings.Count -gt 0) {
    "warning"
}
else {
    "pass"
}

$evidenceLines = ($evidenceChecks + $importChecks | ForEach-Object {
    "- [" + $_.Mark + "] " + $_.Label + " -> " + $_.Status + " -> " + $_.Value
}) -join "`r`n"

$failureLines = if ($failures.Count -gt 0) {
    ($failures | ForEach-Object { "- $_" }) -join "`r`n"
}
else {
    "- none"
}

$warningLines = if ($warnings.Count -gt 0) {
    ($warnings | ForEach-Object { "- $_" }) -join "`r`n"
}
else {
    "- none"
}

$recommendation = switch ($overallStatus) {
    "fail" { "- fix the broken evidence chain before treating this VM cycle as complete" }
    "warning" { "- review the warnings, update the session summary, and rerun the audit if needed" }
    default { "- this session evidence chain looks complete enough to keep as the current reference run" }
}

$content = @"
# AhmadOS Test Session Audit

- Audited At: $(Get-Date -Format s)
- Run Label: $(if ([string]::IsNullOrWhiteSpace($resolvedRunLabel)) { "not-recorded-yet" } else { $resolvedRunLabel })
- Session Path: $resolvedSessionPath
- Mode: $(if ([string]::IsNullOrWhiteSpace($mode)) { "unknown" } else { $mode })
- VM Type: $(if ([string]::IsNullOrWhiteSpace($vmType)) { "unknown" } else { $vmType })
- ISO Path: $(if ([string]::IsNullOrWhiteSpace($isoPath)) { "not-recorded-yet" } else { $isoPath })
- Overall Status: $overallStatus

## Evidence Checks
$evidenceLines

## Failures
$failureLines

## Warnings
$warningLines

## Recommendation
$recommendation
"@

Set-Content -Path $auditPath -Value $content -Encoding UTF8

if ($FailOnMissing -and $overallStatus -eq "fail") {
    Write-Error "AhmadOS test session audit failed. See: $auditPath"
}

if ($OutputPathOnly) {
    Write-Output $auditPath
}
else {
    Write-Host "Created AhmadOS test session audit:"
    Write-Host $auditPath
    Write-Host "Overall status: $overallStatus"
}
