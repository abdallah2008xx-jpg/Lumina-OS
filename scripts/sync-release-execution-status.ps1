param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPath,
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$controlCenterScript = Join-Path $PSScriptRoot "sync-release-control-center.ps1"
if (-not (Test-Path $controlCenterScript)) {
    throw "Missing helper script: $controlCenterScript"
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

function Get-RecordedValue {
    param(
        [string]$Content,
        [string]$Label,
        [string]$DefaultValue = "not-recorded-yet"
    )

    $value = Get-MetadataValue -Content $Content -Label $Label
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }

    return $value
}

function Get-SafeFileSegment {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unnamed"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\.\-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unnamed"
    }

    return $safe
}

function Format-Items {
    param([System.Collections.Generic.List[string]]$Items)

    if ($Items.Count -eq 0) {
        return "- none"
    }

    return ($Items | ForEach-Object { "- $_" }) -join "`r`n"
}

function Get-ResolvedValue {
    param(
        [string]$Value,
        [string]$DefaultValue = "not-recorded-yet"
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $DefaultValue
    }

    return $Value
}

if (-not (Test-Path $ExecutionPath)) {
    throw "Release execution path not found: $ExecutionPath"
}

$resolvedExecutionPath = (Resolve-Path $ExecutionPath).Path
$executionContent = Get-Content -Raw $resolvedExecutionPath

$createdAt = Get-RecordedValue -Content $executionContent -Label "Created At"
$executionState = Get-RecordedValue -Content $executionContent -Label "Execution State"
$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$releaseVersion = Get-RecordedValue -Content $executionContent -Label "Release Version"
$mode = Get-RecordedValue -Content $executionContent -Label "Mode"
$vmType = Get-RecordedValue -Content $executionContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $executionContent -Label "Firmware"
$cycleHandoffPath = Get-RecordedValue -Content $executionContent -Label "Cycle Handoff"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$evidencePackPath = Get-RecordedValue -Content $executionContent -Label "Evidence Pack"
$runbookPath = Get-RecordedValue -Content $executionContent -Label "Runbook Path"
$currentEvidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Current Evidence Session"
$currentControlCenterPath = Get-RecordedValue -Content $executionContent -Label "Current Release Control Center"

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Run Label: $runLabel") | Out-Null
$summaryItems.Add("Mode: $mode") | Out-Null
$summaryItems.Add("Execution State: $executionState") | Out-Null

$nextItems = [System.Collections.Generic.List[string]]::new()
switch ($executionState) {
    "ready-to-execute" {
        $nextItems.Add("Use the cycle handoff to run the labeled VM validation flow.") | Out-Null
        $nextItems.Add("Use the evidence session to collect login-test, install, and hardware evidence on the same run label.") | Out-Null
    }
    default {
        $nextItems.Add("Review the linked handoff and evidence session before continuing the release chain.") | Out-Null
    }
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$safeSuffix = if ($runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment (Split-Path -LeafBase $resolvedExecutionPath)
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("release-execution-status-" + $safeSuffix + ".md")
$currentStatusPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-EXECUTION.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentStatusPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Execution Summary

- Updated At: $(Get-Date -Format s)
- Execution State: $executionState
- Release Execution: $resolvedExecutionPath
- Run Label: $runLabel
- Release Version: $releaseVersion
- Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- Created At: $createdAt
- Cycle Handoff: $cycleHandoffPath
- Evidence Session: $evidenceSessionPath
- Evidence Pack: $evidencePackPath
- Runbook Path: $runbookPath
- Current Evidence Session: $currentEvidenceSessionPath
- Current Release Control Center: $currentControlCenterPath

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

$currentContent = @"
# Lumina-OS Current Release Execution

- Updated At: $(Get-Date -Format s)
- Execution State: $executionState
- Latest Summary: $summaryPath
- Release Execution: $resolvedExecutionPath
- Run Label: $runLabel
- Release Version: $releaseVersion
- Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- Cycle Handoff: $(Get-ResolvedValue -Value $cycleHandoffPath)
- Evidence Session: $(Get-ResolvedValue -Value $evidenceSessionPath)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Runbook Path: $(Get-ResolvedValue -Value $runbookPath)

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentStatusPath -Value $currentContent -Encoding UTF8

$null = & $controlCenterScript `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Updated current release execution:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $executionState"
}
