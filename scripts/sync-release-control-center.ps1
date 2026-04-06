param(
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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

function Get-ContentIfExists {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path $Path)) {
        return Get-Content -Raw $Path
    }

    return ""
}

function Get-FirstNonEmptyValue {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "not-recorded-yet") {
            return $value
        }
    }

    return ""
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

$currentEvidencePackPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-PACK.md"
$currentEvidenceAuditPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-EVIDENCE.md"
$currentReadinessPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-READINESS.md"
$currentCandidatePath = Join-Path $RepoRoot "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md"

$evidencePackContent = Get-ContentIfExists -Path $currentEvidencePackPath
$evidenceAuditContent = Get-ContentIfExists -Path $currentEvidenceAuditPath
$readinessContent = Get-ContentIfExists -Path $currentReadinessPath
$candidateContent = Get-ContentIfExists -Path $currentCandidatePath

$version = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $candidateContent -Label "Version"),
    (Get-MetadataValue -Content $readinessContent -Label "Version"),
    (Get-MetadataValue -Content $evidenceAuditContent -Label "Version"),
    (Get-MetadataValue -Content $evidencePackContent -Label "Release Version")
)

$mode = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $candidateContent -Label "Mode"),
    (Get-MetadataValue -Content $readinessContent -Label "Mode"),
    (Get-MetadataValue -Content $evidenceAuditContent -Label "Mode"),
    (Get-MetadataValue -Content $evidencePackContent -Label "Primary Mode")
)

$runLabel = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $candidateContent -Label "Run Label"),
    (Get-MetadataValue -Content $readinessContent -Label "Run Label"),
    (Get-MetadataValue -Content $evidenceAuditContent -Label "Run Label"),
    (Get-MetadataValue -Content $evidencePackContent -Label "Run Label")
)

$packState = Get-MetadataValue -Content $evidencePackContent -Label "Evidence Pack State"
$evidenceAuditState = Get-MetadataValue -Content $evidenceAuditContent -Label "Evidence Audit State"
$readinessState = Get-MetadataValue -Content $readinessContent -Label "Overall Readiness"
$candidateState = Get-MetadataValue -Content $candidateContent -Label "Candidate State"

$controlState = switch ($true) {
    { $candidateState -eq "published" } { "published"; break }
    { $candidateState -eq "ready-to-publish" -and $readinessState -eq "ready-to-publish" } { "ready-to-publish"; break }
    { $readinessState -eq "ready-to-publish" } { "candidate-sync-needed"; break }
    { $readinessState -eq "ready-for-strict-release-candidate" } { "ready-for-strict-rc"; break }
    { $evidenceAuditState -eq "soft-and-strict-passed" } { "ready-for-readiness-audit"; break }
    { $packState -eq "ready-for-rc-gating" } { "ready-for-evidence-audit"; break }
    default { "not-ready" }
}

$summaryItems = [System.Collections.Generic.List[string]]::new()
$summaryItems.Add("Evidence Pack State: $(Get-ResolvedValue -Value $packState)") | Out-Null
$summaryItems.Add("Evidence Audit State: $(Get-ResolvedValue -Value $evidenceAuditState)") | Out-Null
$summaryItems.Add("Release Readiness: $(Get-ResolvedValue -Value $readinessState)") | Out-Null
$summaryItems.Add("Release Candidate State: $(Get-ResolvedValue -Value $candidateState)") | Out-Null

$nextItems = [System.Collections.Generic.List[string]]::new()
switch ($controlState) {
    "published" {
        $nextItems.Add("Keep this file as the active release trace until the next cycle begins.") | Out-Null
    }
    "ready-to-publish" {
        $nextItems.Add("Validate GitHub release context and publish when wording and assets are final.") | Out-Null
    }
    "candidate-sync-needed" {
        $nextItems.Add("Refresh the current release candidate so it matches the latest readiness audit.") | Out-Null
    }
    "ready-for-strict-rc" {
        $nextItems.Add("Prepare a strict release candidate from the current evidence chain.") | Out-Null
    }
    "ready-for-readiness-audit" {
        $nextItems.Add("Run release-readiness audit from the current evidence chain.") | Out-Null
    }
    "ready-for-evidence-audit" {
        $nextItems.Add("Run release-evidence audit from the current evidence pack.") | Out-Null
    }
    default {
        $nextItems.Add("Finish missing login/install/hardware evidence and sync the evidence pack again.") | Out-Null
    }
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$summaryRoot = Join-Path $RepoRoot ("status\releases\" + $dateStamp)
$safeSuffix = if ([string]::IsNullOrWhiteSpace($runLabel) -or $runLabel -eq "not-recorded-yet") {
    Get-SafeFileSegment $version
}
else {
    Get-SafeFileSegment $runLabel
}
$summaryPath = Join-Path $summaryRoot ("release-control-center-" + $safeSuffix + ".md")
$currentPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"

New-Item -ItemType Directory -Force -Path $summaryRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $currentPath -Parent) | Out-Null

$summaryContent = @"
# Lumina-OS Release Control Center

- Updated At: $(Get-Date -Format s)
- Release Control State: $controlState
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Current Evidence Pack: $(if (Test-Path $currentEvidencePackPath) { $currentEvidencePackPath } else { "not-recorded-yet" })
- Current Release Evidence: $(if (Test-Path $currentEvidenceAuditPath) { $currentEvidenceAuditPath } else { "not-recorded-yet" })
- Current Release Readiness: $(if (Test-Path $currentReadinessPath) { $currentReadinessPath } else { "not-recorded-yet" })
- Current Release Candidate: $(if (Test-Path $currentCandidatePath) { $currentCandidatePath } else { "not-recorded-yet" })

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

$currentContent = @"
# Lumina-OS Current Release Control Center

- Updated At: $(Get-Date -Format s)
- Release Control State: $controlState
- Latest Summary: $summaryPath
- Version: $(Get-ResolvedValue -Value $version)
- Mode: $(Get-ResolvedValue -Value $mode)
- Run Label: $(Get-ResolvedValue -Value $runLabel)
- Current Evidence Pack: $(if (Test-Path $currentEvidencePackPath) { $currentEvidencePackPath } else { "not-recorded-yet" })
- Current Release Evidence: $(if (Test-Path $currentEvidenceAuditPath) { $currentEvidenceAuditPath } else { "not-recorded-yet" })
- Current Release Readiness: $(if (Test-Path $currentReadinessPath) { $currentReadinessPath } else { "not-recorded-yet" })
- Current Release Candidate: $(if (Test-Path $currentCandidatePath) { $currentCandidatePath } else { "not-recorded-yet" })

## Summary
$(Format-Items -Items $summaryItems)

## Next Step
$(Format-Items -Items $nextItems)
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
Set-Content -Path $currentPath -Value $currentContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $summaryPath
}
else {
    Write-Host "Updated release control center:"
    Write-Host "Summary: $summaryPath"
    Write-Host "State:   $controlState"
}
