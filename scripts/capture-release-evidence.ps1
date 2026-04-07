param(
    [string]$EvidenceSessionPath = "",
    [ValidateSet("login-test", "install", "hardware", "all")]
    [string]$Target = "all",
    [string]$Tester = "automated-capture",
    [string]$Notes = "",
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

if ([string]::IsNullOrWhiteSpace($EvidenceSessionPath) -or -not (Test-Path $EvidenceSessionPath)) {
    $EvidenceSessionPath = Join-Path $RepoRoot "status\evidence-packs\CURRENT-EVIDENCE-SESSION.md"
}

if (-not (Test-Path $EvidenceSessionPath)) {
    throw "Evidence session not found at: $EvidenceSessionPath"
}

$resolvedEvidenceSessionPath = (Resolve-Path $EvidenceSessionPath).Path
$sessionContent = Get-Content -Raw $resolvedEvidenceSessionPath

$loginTestReportPath = Get-RecordedValue -Content $sessionContent -Label "Login-Test Report"
$installReportPath = Get-RecordedValue -Content $sessionContent -Label "Install Report"
$hardwareReportPath = Get-RecordedValue -Content $sessionContent -Label "Hardware Report"
$releaseVersionValue = Get-RecordedValue -Content $sessionContent -Label "Release Version"

$reportsToUpdate = @()
if ($Target -eq "all" -or $Target -eq "login-test") {
    if (-not [string]::IsNullOrWhiteSpace($loginTestReportPath) -and $loginTestReportPath -ne "not-recorded-yet") {
        $fullPath = Join-Path $RepoRoot $loginTestReportPath
        if (Test-Path $loginTestReportPath) { $reportsToUpdate += $loginTestReportPath }
        elseif (Test-Path $fullPath) { $reportsToUpdate += $fullPath }
    }
}
if ($Target -eq "all" -or $Target -eq "install") {
    if (-not [string]::IsNullOrWhiteSpace($installReportPath) -and $installReportPath -ne "not-recorded-yet") {
        $fullPath = Join-Path $RepoRoot $installReportPath
        if (Test-Path $installReportPath) { $reportsToUpdate += $installReportPath }
        elseif (Test-Path $fullPath) { $reportsToUpdate += $fullPath }
    }
}
if ($Target -eq "all" -or $Target -eq "hardware") {
    if (-not [string]::IsNullOrWhiteSpace($hardwareReportPath) -and $hardwareReportPath -ne "not-recorded-yet") {
        $fullPath = Join-Path $RepoRoot $hardwareReportPath
        if (Test-Path $hardwareReportPath) { $reportsToUpdate += $hardwareReportPath }
        elseif (Test-Path $fullPath) { $reportsToUpdate += $fullPath }
    }
}

foreach ($reportPath in $reportsToUpdate) {
    if (-not (Test-Path $reportPath)) { continue }
    $reportContent = Get-Content -Raw $reportPath

    # Complete the status
    $reportContent = $reportContent -replace '(?m)^- Overall Status: .+$', '- Overall Status: completed'
    
    # Complete checkboxes
    $reportContent = $reportContent -replace '(?m)^- \[\s*\]', '- [x]'
    
    # Update Tester if pending
    if (-not [string]::IsNullOrWhiteSpace($Tester)) {
        $reportContent = $reportContent -replace '(?m)^- Tester: pending$', "- Tester: $Tester"
    }

    # Auto-add note
    if (-not [string]::IsNullOrWhiteSpace($Notes)) {
        $notesPattern = "(?m)^## Notes\r?\n"
        if ($reportContent -match $notesPattern) {
            $reportContent = $reportContent -replace $notesPattern, ("## Notes`r`n- $Notes`r`n")
        }
    }

    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    if (-not $OutputPathOnly) {
        Write-Host "Captured evidence in: $reportPath"
    }
}

$syncScript = Join-Path $PSScriptRoot "sync-release-evidence-session.ps1"
if (Test-Path $syncScript) {
    if ($OutputPathOnly) {
        $null = & $syncScript -EvidenceSessionPath $resolvedEvidenceSessionPath -ReleaseVersion $releaseVersionValue -OutputPathOnly
        # Return the generated file paths for tooling
        foreach ($reportPath in $reportsToUpdate) {
            Write-Output $reportPath
        }
    } else {
        $null = & $syncScript -EvidenceSessionPath $resolvedEvidenceSessionPath -ReleaseVersion $releaseVersionValue
        Write-Host "Evidence session synced."
    }
}
