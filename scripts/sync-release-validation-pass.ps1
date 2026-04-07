param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPath,
    [string]$ReleaseVersion = "",
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

function Set-OrAddMetadataValue {
    param(
        [string]$Content,
        [string]$Label,
        [string]$Value
    )

    $metadataLine = "- ${Label}: $Value"
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Content -split "`r?`n", -1)) {
        $lines.Add($line) | Out-Null
    }

    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ('^- ' + [regex]::Escape($Label) + ': ')) {
            $lines[$i] = $metadataLine
            $found = $true
            break
        }
    }

    if (-not $found) {
        $insertIndex = $lines.Count
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^## ') {
                $insertIndex = $i
                break
            }
        }

        $lines.Insert($insertIndex, $metadataLine)
    }

    return ($lines -join "`r`n")
}

function Test-PassState {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "not-recorded-yet") {
        return $false
    }

    $normalized = $Value.Trim().ToLowerInvariant()
    return @(
        "pass",
        "passed",
        "complete",
        "completed",
        "success",
        "successful",
        "ready-for-release",
        "ready-for-real-device-smoke"
    ) -contains $normalized
}

$runbookScript = Join-Path $PSScriptRoot "new-release-validation-runbook.ps1"
$workboardScript = Join-Path $PSScriptRoot "new-release-validation-workboard.ps1"
$actionPackScript = Join-Path $PSScriptRoot "new-release-validation-action-pack.ps1"
$syncExecutionStatusScript = Join-Path $PSScriptRoot "sync-release-execution-status.ps1"
$syncEvidenceSessionScript = Join-Path $PSScriptRoot "sync-release-evidence-session.ps1"
$syncControlCenterScript = Join-Path $PSScriptRoot "sync-release-control-center.ps1"

foreach ($requiredScript in @($runbookScript, $workboardScript, $actionPackScript, $syncExecutionStatusScript, $syncEvidenceSessionScript, $syncControlCenterScript)) {
    if (-not (Test-Path $requiredScript)) {
        throw "Missing helper script: $requiredScript"
    }
}

if (-not (Test-Path $ExecutionPath)) {
    throw "Release execution path not found: $ExecutionPath"
}

$resolvedExecutionPath = (Resolve-Path $ExecutionPath).Path
$executionContent = Get-Content -Raw $resolvedExecutionPath

$releaseVersionValue = if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Get-RecordedValue -Content $executionContent -Label "Release Version" -DefaultValue "0.1.0-dev"
}
else {
    $ReleaseVersion.Trim()
}

$evidenceSessionPath = Get-RecordedValue -Content $executionContent -Label "Evidence Session" -DefaultValue ""
if (-not [string]::IsNullOrWhiteSpace($evidenceSessionPath) -and $evidenceSessionPath -ne "not-recorded-yet" -and (Test-Path $evidenceSessionPath)) {
    $null = & $syncEvidenceSessionScript `
        -EvidenceSessionPath $evidenceSessionPath `
        -ReleaseVersion $releaseVersionValue `
        -RepoRoot $RepoRoot `
        -OutputPathOnly
}

$null = & $syncControlCenterScript `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$currentEvidenceSessionPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"
$currentReleaseControlCenterPath = Join-Path $RepoRoot "status\releases\CURRENT-RELEASE-CONTROL-CENTER.md"

$resolvedEvidenceSessionPath = ""
$evidenceSessionContent = ""
if (-not [string]::IsNullOrWhiteSpace($evidenceSessionPath) -and $evidenceSessionPath -ne "not-recorded-yet" -and (Test-Path $evidenceSessionPath)) {
    $resolvedEvidenceSessionPath = (Resolve-Path $evidenceSessionPath).Path
    $evidenceSessionContent = Get-Content -Raw $resolvedEvidenceSessionPath
}

$evidencePackState = Get-RecordedValue -Content $evidenceSessionContent -Label "Evidence Pack State"
$loginTestStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Login-Test Status"
$installStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Install Status"
$hardwareStatus = Get-RecordedValue -Content $evidenceSessionContent -Label "Hardware Status"

$executionState = switch ($evidencePackState) {
    "ready-for-rc-gating" { "ready-for-rc-gating"; break }
    "run-label-mismatch" { "evidence-run-label-mismatch"; break }
    "missing-evidence" {
        if (-not (Test-PassState -Value $loginTestStatus)) {
            "awaiting-login-test-evidence"
        }
        elseif (-not (Test-PassState -Value $installStatus)) {
            "awaiting-install-evidence"
        }
        elseif (-not (Test-PassState -Value $hardwareStatus)) {
            "awaiting-hardware-evidence"
        }
        else {
            "evidence-in-progress"
        }
        break
    }
    "incomplete" {
        if (-not (Test-PassState -Value $loginTestStatus)) {
            "awaiting-login-test-evidence"
        }
        elseif (-not (Test-PassState -Value $installStatus)) {
            "awaiting-install-evidence"
        }
        elseif (-not (Test-PassState -Value $hardwareStatus)) {
            "awaiting-hardware-evidence"
        }
        else {
            "evidence-in-progress"
        }
        break
    }
    default { "ready-to-execute" }
}

$actionPackPath = & $actionPackScript `
    -ExecutionPath $resolvedExecutionPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$executionContent = Set-OrAddMetadataValue -Content $executionContent -Label "Action Pack Path" -Value $actionPackPath
Set-Content -Path $resolvedExecutionPath -Value $executionContent -Encoding UTF8

$executionRunbookPath = & $runbookScript `
    -ExecutionPath $resolvedExecutionPath `
    -ReleaseVersion $releaseVersionValue `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$executionWorkboardPath = & $workboardScript `
    -ExecutionPath $resolvedExecutionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

$updatedExecutionContent = $executionContent
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Release Version" -Value $releaseVersionValue
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Synced At" -Value (Get-Date -Format s)
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Execution State" -Value $executionState
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Evidence Pack State" -Value $evidencePackState
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Login-Test Status" -Value $loginTestStatus
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Install Status" -Value $installStatus
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Hardware Status" -Value $hardwareStatus
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Execution Runbook Path" -Value $executionRunbookPath
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Workboard Path" -Value $executionWorkboardPath
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Action Pack Path" -Value $actionPackPath
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Current Evidence Session" -Value $(if (Test-Path $currentEvidenceSessionPath) { $currentEvidenceSessionPath } else { "not-recorded-yet" })
$updatedExecutionContent = Set-OrAddMetadataValue -Content $updatedExecutionContent -Label "Current Release Control Center" -Value $(if (Test-Path $currentReleaseControlCenterPath) { $currentReleaseControlCenterPath } else { "not-recorded-yet" })

Set-Content -Path $resolvedExecutionPath -Value $updatedExecutionContent -Encoding UTF8

$null = & $syncExecutionStatusScript `
    -ExecutionPath $resolvedExecutionPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $resolvedExecutionPath
}
else {
    Write-Host "Synced release validation pass:"
    Write-Host $resolvedExecutionPath
}
