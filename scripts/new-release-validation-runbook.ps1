param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPath,
    [string]$ReleaseVersion = "",
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

$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Get-RecordedValue -Content $executionContent -Label "Release Version" -DefaultValue "0.1.0-dev"
}
else {
    $ReleaseVersion.Trim()
}

$runLabel = Get-RecordedValue -Content $executionContent -Label "Run Label"
$mode = Get-RecordedValue -Content $executionContent -Label "Mode" -DefaultValue "stable"
$vmType = Get-RecordedValue -Content $executionContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $executionContent -Label "Firmware"
$cycleHandoffPath = Get-RecordedValue -Content $executionContent -Label "Cycle Handoff"
$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session"
$evidencePackPath = Get-RecordedValue -Content $executionContent -Label "Evidence Pack"
$evidenceRunbookPath = Get-RecordedValue -Content $executionContent -Label "Runbook Path"

$executionLeaf = Split-Path -Leaf $resolvedExecutionPath
$runbookLeaf = if ($executionLeaf -like "release-validation-pass-*.md") {
    $executionLeaf -replace "^release-validation-pass-", "release-validation-runbook-"
}
else {
    "release-validation-runbook.md"
}
$runbookPath = Join-Path (Split-Path -Parent $resolvedExecutionPath) $runbookLeaf

$content = @"
# Lumina-OS Release Validation Runbook

- Generated At: $(Get-Date -Format s)
- Release Execution: $resolvedExecutionPath
- Release Version: $releaseVersionValue
- Run Label: $runLabel
- Mode: $mode
- VM Type: $vmType
- Firmware: $firmware
- Cycle Handoff: $cycleHandoffPath
- Evidence Session: $evidenceSessionPath
- Evidence Pack: $evidencePackPath
- Evidence Runbook: $evidenceRunbookPath

## Step 1: Follow Cycle Handoff
Use this file as the VM-cycle guide for the selected run label:

$cycleHandoffPath

## Step 2: Follow Evidence Session
Use this file while collecting the real login-test, install, and hardware evidence:

$evidenceSessionPath

## Step 3: Sync Shared Evidence
After report updates, refresh the pack:

```powershell
.\scripts\sync-release-evidence-pack.ps1 -EvidencePackPath "$evidencePackPath" -ReleaseVersion "$releaseVersionValue"
```

## Step 4: Refresh This Validation Pass
After evidence updates, refresh the execution, runbook, and workboard together:

```powershell
.\scripts\sync-release-validation-pass.ps1 -ExecutionPath "$resolvedExecutionPath" -ReleaseVersion "$releaseVersionValue"
```

## Step 5: Review Current Pointers
- `status\\releases\\CURRENT-RELEASE-EXECUTION.md`
- `status\\evidence-packs\\CURRENT-EVIDENCE-SESSION.md`
- `status\\evidence-packs\\CURRENT-EVIDENCE-PACK.md`
- `status\\releases\\CURRENT-RELEASE-CONTROL-CENTER.md`

## Step 6: Run Evidence Audit
```powershell
.\scripts\audit-release-evidence.ps1 -Version "$releaseVersionValue" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"
```

## Step 7: Prepare Release Candidate
```powershell
.\scripts\prepare-release-candidate.ps1 -Version "$releaseVersionValue" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"
```

## Step 8: Run Readiness Audit
```powershell
.\scripts\audit-release-readiness.ps1 -Version "$releaseVersionValue" -Mode $mode -RunLabel "$runLabel" -EvidencePackPath "$evidencePackPath"
```

## Notes
- keep this runbook on the same run label as the cycle handoff and evidence session
- if the evidence pack is regenerated or replaced, refresh this validation pass too
- if you want the evidence-only detail view, use the linked evidence runbook:
  $evidenceRunbookPath
"@

Set-Content -Path $runbookPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $runbookPath
}
else {
    Write-Host "Created release validation runbook:"
    Write-Host $runbookPath
}
