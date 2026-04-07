param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPath,
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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

if (-not (Test-Path $ExecutionPath)) {
    throw "Execution path not found: $ExecutionPath"
}

$resolvedExecutionPath = (Resolve-Path $ExecutionPath).Path
$executionContent = Get-Content -Raw $resolvedExecutionPath

$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$releaseVersion = Get-RecordedValue -Content $executionContent -Label "Release Version"
$mode = Get-RecordedValue -Content $executionContent -Label "Mode"
$vmType = Get-RecordedValue -Content $executionContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $executionContent -Label "Firmware"
$cycleHandoffPath = Get-RecordedValue -Content $executionContent -Label "Cycle Handoff"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$evidencePackPath = Get-RecordedValue -Content $executionContent -Label "Evidence Pack"
$evidenceRunbookPath = Get-RecordedValue -Content $executionContent -Label "Runbook Path"
$executionRunbookPath = Get-RecordedValue -Content $executionContent -Label "Execution Runbook Path"

$executionLeaf = Split-Path -Leaf $resolvedExecutionPath
$workboardLeaf = if ($executionLeaf -like "release-validation-pass-*.md") {
    $executionLeaf -replace "^release-validation-pass-", "release-validation-workboard-"
}
else {
    "release-validation-workboard.md"
}
$workboardPath = Join-Path (Split-Path -Parent $resolvedExecutionPath) $workboardLeaf

$content = @"
# Lumina-OS Release Validation Workboard

- Generated At: $(Get-Date -Format s)
- Release Execution: $resolvedExecutionPath
- Run Label: $runLabel
- Release Version: $releaseVersion
- Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- Cycle Handoff: $cycleHandoffPath
- Evidence Session: $evidenceSessionPath
- Evidence Pack: $evidencePackPath
- Evidence Runbook: $evidenceRunbookPath
- Execution Runbook: $executionRunbookPath

## Track Now
- [ ] Run the VM cycle from: $cycleHandoffPath
- [ ] Update login-test evidence from: $evidenceSessionPath
- [ ] Update install evidence from: $evidenceSessionPath
- [ ] Update hardware evidence from: $evidenceSessionPath
- [ ] Sync the shared evidence pack after report updates
- [ ] Review the current pointers before RC prep
- [ ] Run evidence audit
- [ ] Prepare the release candidate
- [ ] Run readiness audit

## Commands
- .\scripts\sync-release-evidence-pack.ps1 -EvidencePackPath "$evidencePackPath" -ReleaseVersion "$releaseVersion"
- .\scripts\audit-release-evidence.ps1 -Version "$releaseVersion" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"
- .\scripts\prepare-release-candidate.ps1 -Version "$releaseVersion" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"
- .\scripts\audit-release-readiness.ps1 -Version "$releaseVersion" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"

## Review Pointers
- status\\releases\\CURRENT-RELEASE-EXECUTION.md
- status\\evidence-packs\\CURRENT-EVIDENCE-SESSION.md
- status\\evidence-packs\\CURRENT-EVIDENCE-PACK.md
- status\\releases\\CURRENT-RELEASE-EVIDENCE.md
- status\\releases\\CURRENT-RELEASE-READINESS.md
- status\\releases\\CURRENT-RELEASE-CONTROL-CENTER.md
- status\\release-candidates\\CURRENT-RELEASE-CANDIDATE.md
"@

Set-Content -Path $workboardPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $workboardPath
}
else {
    Write-Host "Created release validation workboard:"
    Write-Host $workboardPath
}
