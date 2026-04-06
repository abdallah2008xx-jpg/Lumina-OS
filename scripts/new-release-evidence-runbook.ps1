param(
    [Parameter(Mandatory = $true)]
    [string]$EvidencePackPath,
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

if (-not (Test-Path $EvidencePackPath)) {
    throw "Evidence pack path not found: $EvidencePackPath"
}

$resolvedEvidencePackPath = (Resolve-Path $EvidencePackPath).Path
$packContent = Get-Content -Raw $resolvedEvidencePackPath
$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    "0.1.0-dev"
}
else {
    $ReleaseVersion.Trim()
}

$runLabel = Get-RecordedValue -Content $packContent -Label "Run Label"
$mode = Get-RecordedValue -Content $packContent -Label "Primary Mode" -DefaultValue "stable"
$vmType = Get-RecordedValue -Content $packContent -Label "VM Type"
$firmware = Get-RecordedValue -Content $packContent -Label "Firmware"
$isoPath = Get-RecordedValue -Content $packContent -Label "ISO Path"
$loginTestReport = Get-RecordedValue -Content $packContent -Label "Login-Test Report"
$installReport = Get-RecordedValue -Content $packContent -Label "Install Report"
$hardwareReport = Get-RecordedValue -Content $packContent -Label "Hardware Report"

$packLeaf = Split-Path -Leaf $resolvedEvidencePackPath
$runbookLeaf = if ($packLeaf -like "release-evidence-pack-*.md") {
    $packLeaf -replace "^release-evidence-pack-", "release-evidence-runbook-"
}
else {
    "release-evidence-runbook.md"
}
$runbookPath = Join-Path (Split-Path -Parent $resolvedEvidencePackPath) $runbookLeaf

$template = @'
# Lumina-OS Release Evidence Runbook

- Generated At: __GENERATED_AT__
- Evidence Pack: __EVIDENCE_PACK__
- Release Version: __RELEASE_VERSION__
- Run Label: __RUN_LABEL__
- Mode: __MODE__
- VM Type: __VM_TYPE__
- Firmware: __FIRMWARE__
- ISO Path: __ISO_PATH__
- Login-Test Report: __LOGIN_TEST_REPORT__
- Install Report: __INSTALL_REPORT__
- Hardware Report: __HARDWARE_REPORT__

## Purpose
- use one shared evidence pack from validation through RC gating
- reduce path drift between `login-test`, `install`, `hardware`, and release prep

## Step 1: Audit Release Evidence
Soft + strict evidence view from the same pack:

```powershell
.\scripts\audit-release-evidence.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel "__RUN_LABEL__" -EvidencePackPath "__EVIDENCE_PACK__"
```

## Step 2: Prepare Release Candidate
Standard candidate pass from the same pack:

```powershell
.\scripts\prepare-release-candidate.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel "__RUN_LABEL__" -IsoPath "__ISO_PATH__" -EvidencePackPath "__EVIDENCE_PACK__"
```

Strict candidate pass when the evidence must stay exact:

```powershell
.\scripts\prepare-release-candidate.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel "__RUN_LABEL__" -IsoPath "__ISO_PATH__" -EvidencePackPath "__EVIDENCE_PACK__" -RequireExactEvidenceRunLabel
```

## Step 3: Audit Release Readiness
Go/no-go summary from the same pack:

```powershell
.\scripts\audit-release-readiness.ps1 -Version "__RELEASE_VERSION__" -Mode __MODE__ -RunLabel "__RUN_LABEL__" -IsoPath "__ISO_PATH__" -EvidencePackPath "__EVIDENCE_PACK__"
```

## Step 4: Validate GitHub Release Context
Use this after the candidate is ready:

```powershell
.\scripts\validate-github-release-context.ps1 -ReleaseManifestPath "C:\Path\To\release-manifest.md" -RequireExactEvidenceRunLabel
```

## Notes
- if `Release Version` changes, regenerate this runbook or update the version in the commands above
- keep this pack and its runbook on the same `Run Label`
- if any evidence file is replaced, rerun `new-release-evidence-runbook.ps1`
'@

$content = $template.Replace("__GENERATED_AT__", (Get-Date -Format s)).
    Replace("__EVIDENCE_PACK__", $resolvedEvidencePackPath).
    Replace("__RELEASE_VERSION__", $releaseVersionValue).
    Replace("__RUN_LABEL__", $runLabel).
    Replace("__MODE__", $mode).
    Replace("__VM_TYPE__", $vmType).
    Replace("__FIRMWARE__", $firmware).
    Replace("__ISO_PATH__", $isoPath).
    Replace("__LOGIN_TEST_REPORT__", $loginTestReport).
    Replace("__INSTALL_REPORT__", $installReport).
    Replace("__HARDWARE_REPORT__", $hardwareReport)

Set-Content -Path $runbookPath -Value $content -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $runbookPath
}
else {
    Write-Host "Created release evidence runbook:"
    Write-Host $runbookPath
}
