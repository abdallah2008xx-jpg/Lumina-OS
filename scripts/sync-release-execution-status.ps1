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

$nextActionScript = Join-Path $PSScriptRoot "open-next-release-action.ps1"
if (-not (Test-Path $nextActionScript)) {
    throw "Missing helper script: $nextActionScript"
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
$syncedAt = Get-RecordedValue -Content $executionContent -Label "Synced At"
$executionState = Get-RecordedValue -Content $executionContent -Label "Execution State"
$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$releaseVersion = Get-RecordedValue -Content $executionContent -Label "Release Version"
$mode = Get-RecordedValue -Content $executionContent -Label "Mode"
$vmType = Get-RecordedValue -Content $executionContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $executionContent -Label "Firmware"
$cycleHandoffPath = Get-RecordedValue -Content $executionContent -Label "Cycle Handoff"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$evidencePackPath = Get-RecordedValue -Content $executionContent -Label "Evidence Pack"
$evidencePackState = Get-RecordedValue -Content $executionContent -Label "Evidence Pack State"
$runbookPath = Get-RecordedValue -Content $executionContent -Label "Runbook Path"
$executionRunbookPath = Get-RecordedValue -Content $executionContent -Label "Execution Runbook Path"
$workboardPath = Get-RecordedValue -Content $executionContent -Label "Workboard Path"
$actionPackPath = Get-RecordedValue -Content $executionContent -Label "Action Pack Path"
$currentEvidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Current Evidence Session"
$currentControlCenterPath = Get-RecordedValue -Content $executionContent -Label "Current Release Control Center"

$evidenceSessionContent = ""
if ($evidenceSessionPath -ne "not-recorded-yet" -and (Test-Path $evidenceSessionPath)) {
    $evidenceSessionContent = Get-Content -Raw $evidenceSessionPath
}

$evidenceReadyCount = Get-RecordedValue -Content $evidenceSessionContent -Label "Evidence Ready Count"
$evidenceChecklistProgress = Get-RecordedValue -Content $evidenceSessionContent -Label "Evidence Checklist Progress"
$loginTestStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Status"
$loginTestReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Report"
$loginTestTester = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Tester"
$loginTestChecklistProgress = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Checklist Progress"
$installStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Status"
$installReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Report"
$installTester = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Tester"
$installChecklistProgress = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Checklist Progress"
$hardwareStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Status"
$hardwareReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Report"
$hardwareTester = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Tester"
$hardwareChecklistProgress = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Checklist Progress"
$nextEvidenceTarget = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Target"
$nextEvidenceReportPath = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Report"
$nextEvidenceTester = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Tester"
$nextEvidenceProgress = Get-RecordedValue -Content $evidenceSessionContent -Label "Next Evidence Progress"
$nextActionPath = & $nextActionScript `
    -ExecutionPath $resolvedExecutionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Run Label: $runLabel") | Out-Null
$summaryItems.Add("Mode: $mode") | Out-Null
$summaryItems.Add("Execution State: $executionState") | Out-Null
$summaryItems.Add("Synced At: $syncedAt") | Out-Null
$summaryItems.Add("Evidence Pack State: $evidencePackState") | Out-Null
$summaryItems.Add("Evidence Ready Count: $evidenceReadyCount") | Out-Null
$summaryItems.Add("Evidence Checklist Progress: $evidenceChecklistProgress") | Out-Null
$summaryItems.Add("Login-Test Status: $loginTestStatus") | Out-Null
$summaryItems.Add("Install Status: $installStatus") | Out-Null
$summaryItems.Add("Hardware Status: $hardwareStatus") | Out-Null
$summaryItems.Add("Next Action Path: $nextActionPath") | Out-Null

$nextItems = [System.Collections.Generic.List[string]]::new()
switch ($executionState) {
    "ready-to-execute" {
        $nextItems.Add("Use the cycle handoff to run the labeled VM validation flow.") | Out-Null
        $nextItems.Add("Use the evidence session and workboard to collect login-test, install, and hardware evidence on the same run label.") | Out-Null
        $nextItems.Add("Login-Test Report: $loginTestReportPath") | Out-Null
        $nextItems.Add("Install Report: $installReportPath") | Out-Null
        $nextItems.Add("Hardware Report: $hardwareReportPath") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    "awaiting-login-test-evidence" {
        $nextItems.Add("Complete the login-test report before moving to install and hardware evidence.") | Out-Null
        $nextItems.Add("Login-Test Report: $loginTestReportPath") | Out-Null
        $nextItems.Add("Login-Test Progress: $loginTestChecklistProgress") | Out-Null
        $nextItems.Add("Login-Test Tester: $loginTestTester") | Out-Null
        if ($actionPackPath -ne "not-recorded-yet") {
            $nextItems.Add("Action Pack: $actionPackPath") | Out-Null
        }
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    "awaiting-install-evidence" {
        $nextItems.Add("Login-test evidence looks good; complete the install report next.") | Out-Null
        $nextItems.Add("Install Report: $installReportPath") | Out-Null
        $nextItems.Add("Install Progress: $installChecklistProgress") | Out-Null
        $nextItems.Add("Install Tester: $installTester") | Out-Null
        if ($actionPackPath -ne "not-recorded-yet") {
            $nextItems.Add("Action Pack: $actionPackPath") | Out-Null
        }
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    "awaiting-hardware-evidence" {
        $nextItems.Add("Login-test and install evidence look good; complete the real-device hardware report next.") | Out-Null
        $nextItems.Add("Hardware Report: $hardwareReportPath") | Out-Null
        $nextItems.Add("Hardware Progress: $hardwareChecklistProgress") | Out-Null
        $nextItems.Add("Hardware Tester: $hardwareTester") | Out-Null
        if ($actionPackPath -ne "not-recorded-yet") {
            $nextItems.Add("Action Pack: $actionPackPath") | Out-Null
        }
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    "ready-for-rc-gating" {
        $nextItems.Add("All three evidence targets look complete for this run label.") | Out-Null
        $nextItems.Add("Run the evidence audit, then prepare the release candidate.") | Out-Null
        if ($actionPackPath -ne "not-recorded-yet") {
            $nextItems.Add("Action Pack: $actionPackPath") | Out-Null
        }
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    "evidence-run-label-mismatch" {
        $nextItems.Add("One or more evidence reports do not match the release run label.") | Out-Null
        $nextItems.Add("Re-run or relink the mismatched evidence before RC gating.") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
    }
    default {
        $nextItems.Add("Review the linked handoff and evidence session before continuing the release chain.") | Out-Null
        $nextItems.Add("Next Action Path: $nextActionPath") | Out-Null
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
- Synced At: $syncedAt
- Cycle Handoff: $cycleHandoffPath
- Evidence Session: $evidenceSessionPath
- Evidence Pack: $evidencePackPath
- Evidence Pack State: $evidencePackState
- Evidence Ready Count: $evidenceReadyCount
- Evidence Checklist Progress: $evidenceChecklistProgress
- Runbook Path: $runbookPath
- Execution Runbook Path: $executionRunbookPath
- Workboard Path: $workboardPath
- Action Pack Path: $actionPackPath
- Login-Test Report: $loginTestReportPath
- Login-Test Status: $loginTestStatus
- Login-Test Tester: $loginTestTester
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Install Report: $installReportPath
- Install Status: $installStatus
- Install Tester: $installTester
- Install Checklist Progress: $installChecklistProgress
- Hardware Report: $hardwareReportPath
- Hardware Status: $hardwareStatus
- Hardware Tester: $hardwareTester
- Hardware Checklist Progress: $hardwareChecklistProgress
- Next Evidence Target: $nextEvidenceTarget
- Next Evidence Report: $nextEvidenceReportPath
- Next Evidence Tester: $nextEvidenceTester
- Next Evidence Progress: $nextEvidenceProgress
- Next Action Path: $nextActionPath
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
- Synced At: $syncedAt
- Cycle Handoff: $(Get-ResolvedValue -Value $cycleHandoffPath)
- Evidence Session: $(Get-ResolvedValue -Value $evidenceSessionPath)
- Evidence Pack: $(Get-ResolvedValue -Value $evidencePackPath)
- Evidence Pack State: $evidencePackState
- Evidence Ready Count: $(Get-ResolvedValue -Value $evidenceReadyCount)
- Evidence Checklist Progress: $(Get-ResolvedValue -Value $evidenceChecklistProgress)
- Runbook Path: $(Get-ResolvedValue -Value $runbookPath)
- Execution Runbook Path: $(Get-ResolvedValue -Value $executionRunbookPath)
- Workboard Path: $(Get-ResolvedValue -Value $workboardPath)
- Action Pack Path: $(Get-ResolvedValue -Value $actionPackPath)
- Login-Test Report: $(Get-ResolvedValue -Value $loginTestReportPath)
- Login-Test Status: $loginTestStatus
- Login-Test Checklist Progress: $loginTestChecklistProgress
- Install Report: $(Get-ResolvedValue -Value $installReportPath)
- Install Status: $installStatus
- Install Checklist Progress: $installChecklistProgress
- Hardware Report: $(Get-ResolvedValue -Value $hardwareReportPath)
- Hardware Status: $hardwareStatus
- Hardware Checklist Progress: $hardwareChecklistProgress
- Next Evidence Target: $(Get-ResolvedValue -Value $nextEvidenceTarget)
- Next Evidence Report: $(Get-ResolvedValue -Value $nextEvidenceReportPath)
- Next Evidence Tester: $(Get-ResolvedValue -Value $nextEvidenceTester)
- Next Evidence Progress: $(Get-ResolvedValue -Value $nextEvidenceProgress)
- Next Action Path: $(Get-ResolvedValue -Value $nextActionPath)

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
    Write-Host "Updated release execution status:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $executionState"
}
