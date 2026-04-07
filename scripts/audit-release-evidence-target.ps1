param(
    [Parameter(Mandatory = $true)]
    [string]$ReportPath,
    [string]$Target = "",
    [switch]$AsJson
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

function Get-SectionBody {
    param(
        [string]$Content,
        [string]$Heading
    )

    if ([string]::IsNullOrWhiteSpace($Content) -or [string]::IsNullOrWhiteSpace($Heading)) {
        return ""
    }

    $pattern = "(?ms)^## " + [regex]::Escape($Heading) + "\r?\n(?<body>.*?)(?=^## |\z)"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($match.Success) {
        return $match.Groups["body"].Value.Trim()
    }

    return ""
}

function Get-SectionState {
    param(
        [string]$Content,
        [string]$Heading
    )

    $body = Get-SectionBody -Content $Content -Heading $Heading
    if ([string]::IsNullOrWhiteSpace($body)) {
        return "not-recorded-yet"
    }

    $meaningfulLines = @(
        $body -split "`r?`n" |
            ForEach-Object { $_.Trim() } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and
                $_ -notin @("- none yet", "none yet")
            }
    )

    if ($meaningfulLines.Count -eq 0) {
        return "clear"
    }

    return "reported"
}

function Get-FirstNonEmptyValue {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
    }

    return ""
}

function Get-InferredTarget {
    param(
        [string]$Path,
        [string]$Target
    )

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        return $Target.Trim().ToLowerInvariant()
    }

    $leaf = Split-Path -Leaf $Path
    if ($leaf -match "^login-test-") {
        return "login-test"
    }
    if ($leaf -match "^install-test-") {
        return "install"
    }
    if ($leaf -match "^hardware-test-") {
        return "hardware"
    }

    return "generic"
}

function Get-ChecklistSummary {
    param(
        [int]$Checked,
        [int]$Total
    )

    if ($Total -le 0) {
        return "0/0 complete (0%)"
    }

    $percent = [int][Math]::Round(($Checked / $Total) * 100)
    return "$Checked/$Total complete ($percent%)"
}

$resolvedTarget = Get-InferredTarget -Path $ReportPath -Target $Target
$resolvedPath = if (Test-Path $ReportPath) { (Resolve-Path $ReportPath).Path } else { $ReportPath }

$result = [ordered]@{
    Target = $resolvedTarget
    Path = $resolvedPath
    Exists = $false
    Status = "not-recorded-yet"
    RunLabel = "not-recorded-yet"
    Tester = "pending"
    TotalChecklistItems = 0
    CheckedChecklistItems = 0
    OpenChecklistItems = 0
    ChecklistSummary = "0/0 complete (0%)"
    ProgressPercent = 0
    ProgressState = "missing"
    TesterState = "pending"
    FindingsState = "not-recorded-yet"
    BlockersState = "not-recorded-yet"
    ReadyForGate = $false
}

if (Test-Path $ReportPath) {
    $content = Get-Content -Raw $ReportPath
    $status = Get-FirstNonEmptyValue @(
        (Get-MetadataValue -Content $content -Label "Overall Status"),
        (Get-MetadataValue -Content $content -Label "Hardware Readiness"),
        (Get-MetadataValue -Content $content -Label "Overall State"),
        (Get-MetadataValue -Content $content -Label "Result")
    )
    $runLabel = Get-MetadataValue -Content $content -Label "Run Label"
    $tester = Get-MetadataValue -Content $content -Label "Tester"
    $totalChecklistItems = [regex]::Matches($content, "(?m)^- \[(?: |x)\] ").Count
    $checkedChecklistItems = [regex]::Matches($content, "(?m)^- \[x\] ").Count
    $openChecklistItems = [Math]::Max(0, $totalChecklistItems - $checkedChecklistItems)
    $progressPercent = if ($totalChecklistItems -gt 0) {
        [int][Math]::Round(($checkedChecklistItems / $totalChecklistItems) * 100)
    }
    else {
        0
    }
    $normalizedStatus = if ([string]::IsNullOrWhiteSpace($status)) { "" } else { $status.Trim().ToLowerInvariant() }
    $readyForGate = @(
        "pass",
        "passed",
        "complete",
        "completed",
        "success",
        "successful",
        "ready-for-release",
        "ready-for-real-device-smoke"
    ) -contains $normalizedStatus

    $progressState = if ($totalChecklistItems -le 0) {
        if ($readyForGate) { "completed" } else { "status-only" }
    }
    elseif ($openChecklistItems -eq 0 -and $readyForGate) {
        "completed"
    }
    elseif ($openChecklistItems -eq 0) {
        "checklist-complete-awaiting-status"
    }
    elseif ($checkedChecklistItems -eq 0) {
        "not-started"
    }
    else {
        "in-progress"
    }

    $result.Exists = $true
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        $result.Status = $status
    }
    if (-not [string]::IsNullOrWhiteSpace($runLabel)) {
        $result.RunLabel = $runLabel
    }
    if (-not [string]::IsNullOrWhiteSpace($tester)) {
        $result.Tester = $tester
    }
    $result.TotalChecklistItems = $totalChecklistItems
    $result.CheckedChecklistItems = $checkedChecklistItems
    $result.OpenChecklistItems = $openChecklistItems
    $result.ChecklistSummary = Get-ChecklistSummary -Checked $checkedChecklistItems -Total $totalChecklistItems
    $result.ProgressPercent = $progressPercent
    $result.ProgressState = $progressState
    $result.TesterState = if ([string]::IsNullOrWhiteSpace($tester) -or $tester -eq "pending") { "pending" } else { "recorded" }
    $result.FindingsState = Get-SectionState -Content $content -Heading "Findings"
    $result.BlockersState = Get-SectionState -Content $content -Heading "Blockers"
    $result.ReadyForGate = $readyForGate
}

$outputObject = [pscustomobject]$result

if ($AsJson) {
    $outputObject | ConvertTo-Json -Compress
}
else {
    Write-Output $outputObject
}
