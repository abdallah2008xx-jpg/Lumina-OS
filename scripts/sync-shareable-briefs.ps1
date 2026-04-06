param(
    [string]$ShareableUpdatePath = "",
    [string]$ReleaseCandidatePath = "",
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

function Get-SectionItems {
    param(
        [string]$Content,
        [string]$Heading
    )

    $items = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $items
    }

    $pattern = "(?s)^## " + [regex]::Escape($Heading) + "\r?\n(?<body>.*?)(?=^## |\z)"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $match.Success) {
        return $items
    }

    foreach ($rawLine in ($match.Groups["body"].Value -split "`r?`n")) {
        $line = $rawLine.Trim()
        if ($line.StartsWith("- ")) {
            $items.Add($line.Substring(2).Trim()) | Out-Null
        }
    }

    return $items
}

function Get-TopItems {
    param(
        [System.Collections.Generic.List[string]]$Items,
        [int]$Count
    )

    $result = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt [Math]::Min($Count, $Items.Count); $index++) {
        $result.Add($Items[$index]) | Out-Null
    }

    return $result
}

function Convert-CodepointsToString {
    param([int[]]$Codepoints)

    return -join ($Codepoints | ForEach-Object { [char]$_ })
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

$resolvedShareableUpdatePath = if ([string]::IsNullOrWhiteSpace($ShareableUpdatePath)) {
    Join-Path $RepoRoot "status\SHAREABLE-UPDATE.md"
}
else {
    $ShareableUpdatePath
}

$resolvedReleaseCandidatePath = if ([string]::IsNullOrWhiteSpace($ReleaseCandidatePath)) {
    Join-Path $RepoRoot "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md"
}
else {
    $ReleaseCandidatePath
}

foreach ($requiredPath in @($resolvedShareableUpdatePath, $resolvedReleaseCandidatePath)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required shareable brief input: $requiredPath"
    }
}

$shareableContent = Get-Content -Raw $resolvedShareableUpdatePath
$releaseCandidateContent = Get-Content -Raw $resolvedReleaseCandidatePath

$readinessState = Get-MetadataValue -Content $shareableContent -Label "Readiness State"
$validationState = Get-MetadataValue -Content $shareableContent -Label "Validation Matrix State"
$candidateState = Get-MetadataValue -Content $shareableContent -Label "Release Candidate State"
$evidencePackState = Get-MetadataValue -Content $shareableContent -Label "Release Evidence Pack State"
$releaseReadinessState = Get-MetadataValue -Content $shareableContent -Label "Release Readiness State"
$evidenceSoftGateState = Get-MetadataValue -Content $shareableContent -Label "Release Evidence Soft Gate"
$evidenceStrictGateState = Get-MetadataValue -Content $shareableContent -Label "Release Evidence Strict Gate"
$runLabel = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $releaseCandidateContent -Label "Run Label"),
    (Get-MetadataValue -Content $shareableContent -Label "Current Run Label")
)
$version = Get-FirstNonEmptyValue @(
    (Get-MetadataValue -Content $releaseCandidateContent -Label "Version"),
    (Get-MetadataValue -Content $shareableContent -Label "Current Version")
)

$currentStateItems = Get-SectionItems -Content $shareableContent -Heading "Current State"
$recentProgressItems = Get-SectionItems -Content $shareableContent -Heading "Recent Progress"
$nextItems = Get-SectionItems -Content $shareableContent -Heading "Immediate Next Step"

$topProgress = Get-TopItems -Items $recentProgressItems -Count 3
$topNext = Get-TopItems -Items $nextItems -Count 3

$englishBriefPath = Join-Path $RepoRoot "status\SHAREABLE-BRIEF.md"
$arabicBriefPath = Join-Path $RepoRoot "status\SHAREABLE-BRIEF-AR.md"
$arabicHeadingShort = Convert-CodepointsToString @(0x062A,0x062D,0x062F,0x064A,0x062B,0x0020,0x0645,0x062E,0x062A,0x0635,0x0631)
$arabicPrefixCurrent = Convert-CodepointsToString @(0x0644,0x0648,0x0645,0x064A,0x0646,0x0627,0x002D,0x0623,0x0648,0x002D,0x0625,0x0633,0x0020,0x0627,0x0644,0x0622,0x0646,0x003A,0x0020)
$arabicProjectGood = Convert-CodepointsToString @(0x0627,0x0644,0x0645,0x0634,0x0631,0x0648,0x0639,0x0020,0x064A,0x062A,0x0642,0x062F,0x0645,0x0020,0x0628,0x0634,0x0643,0x0644,0x0020,0x062C,0x064A,0x062F,0x002E)
$arabicHeadingHighlights = Convert-CodepointsToString @(0x0623,0x0628,0x0631,0x0632,0x0020,0x0645,0x0627,0x0020,0x062A,0x0645)
$arabicNone = Convert-CodepointsToString @(0x0644,0x0627,0x0020,0x064A,0x0648,0x062C,0x062F)
$arabicHeadingNext = Convert-CodepointsToString @(0x0627,0x0644,0x062E,0x0637,0x0648,0x0629,0x0020,0x0627,0x0644,0x062A,0x0627,0x0644,0x064A,0x0629)

$englishShortUpdateLine = if ($currentStateItems.Count -gt 0) {
    "- $($currentStateItems[0])"
}
else {
    "- Lumina-OS is progressing steadily."
}

$arabicShortUpdateLine = if ($currentStateItems.Count -gt 0) {
    "- $arabicPrefixCurrent$($currentStateItems[0])"
}
else {
    "- $arabicProjectGood"
}

$englishLines = [System.Collections.Generic.List[string]]::new()
$englishLines.Add("# Lumina-OS Shareable Brief") | Out-Null
$englishLines.Add("") | Out-Null
$englishLines.Add("- Generated At: $(Get-Date -Format s)") | Out-Null
$englishLines.Add("- Readiness State: $(if ([string]::IsNullOrWhiteSpace($readinessState)) { "not-recorded-yet" } else { $readinessState })") | Out-Null
$englishLines.Add("- Validation Matrix State: $(if ([string]::IsNullOrWhiteSpace($validationState)) { "not-recorded-yet" } else { $validationState })") | Out-Null
$englishLines.Add("- Release Candidate State: $(if ([string]::IsNullOrWhiteSpace($candidateState)) { "not-recorded-yet" } else { $candidateState })") | Out-Null
$englishLines.Add("- Release Evidence Pack State: $(if ([string]::IsNullOrWhiteSpace($evidencePackState)) { "not-recorded-yet" } else { $evidencePackState })") | Out-Null
$englishLines.Add("- Release Readiness State: $(if ([string]::IsNullOrWhiteSpace($releaseReadinessState)) { "not-recorded-yet" } else { $releaseReadinessState })") | Out-Null
$englishLines.Add("- Release Evidence Soft Gate: $(if ([string]::IsNullOrWhiteSpace($evidenceSoftGateState)) { "not-recorded-yet" } else { $evidenceSoftGateState })") | Out-Null
$englishLines.Add("- Release Evidence Strict Gate: $(if ([string]::IsNullOrWhiteSpace($evidenceStrictGateState)) { "not-recorded-yet" } else { $evidenceStrictGateState })") | Out-Null
$englishLines.Add("- Current Run Label: $(if ([string]::IsNullOrWhiteSpace($runLabel)) { "not-recorded-yet" } else { $runLabel })") | Out-Null
$englishLines.Add("- Current Version: $(if ([string]::IsNullOrWhiteSpace($version)) { "not-recorded-yet" } else { $version })") | Out-Null
$englishLines.Add("") | Out-Null
$englishLines.Add("## Short Update") | Out-Null
$englishLines.Add($englishShortUpdateLine) | Out-Null
$englishLines.Add("") | Out-Null
$englishLines.Add("## Recent Highlights") | Out-Null
foreach ($item in $topProgress) {
    $englishLines.Add("- $item") | Out-Null
}
if ($topProgress.Count -eq 0) {
    $englishLines.Add("- none") | Out-Null
}
$englishLines.Add("") | Out-Null
$englishLines.Add("## Next Focus") | Out-Null
foreach ($item in $topNext) {
    $englishLines.Add("- $item") | Out-Null
}
if ($topNext.Count -eq 0) {
    $englishLines.Add("- none") | Out-Null
}

$arabicLines = [System.Collections.Generic.List[string]]::new()
$arabicLines.Add("# Lumina-OS Shareable Brief (AR)") | Out-Null
$arabicLines.Add("") | Out-Null
$arabicLines.Add("- Generated At: $(Get-Date -Format s)") | Out-Null
$arabicLines.Add("- Readiness State: $(if ([string]::IsNullOrWhiteSpace($readinessState)) { "not-recorded-yet" } else { $readinessState })") | Out-Null
$arabicLines.Add("- Validation Matrix State: $(if ([string]::IsNullOrWhiteSpace($validationState)) { "not-recorded-yet" } else { $validationState })") | Out-Null
$arabicLines.Add("- Release Candidate State: $(if ([string]::IsNullOrWhiteSpace($candidateState)) { "not-recorded-yet" } else { $candidateState })") | Out-Null
$arabicLines.Add("- Release Evidence Pack State: $(if ([string]::IsNullOrWhiteSpace($evidencePackState)) { "not-recorded-yet" } else { $evidencePackState })") | Out-Null
$arabicLines.Add("- Release Readiness State: $(if ([string]::IsNullOrWhiteSpace($releaseReadinessState)) { "not-recorded-yet" } else { $releaseReadinessState })") | Out-Null
$arabicLines.Add("- Release Evidence Soft Gate: $(if ([string]::IsNullOrWhiteSpace($evidenceSoftGateState)) { "not-recorded-yet" } else { $evidenceSoftGateState })") | Out-Null
$arabicLines.Add("- Release Evidence Strict Gate: $(if ([string]::IsNullOrWhiteSpace($evidenceStrictGateState)) { "not-recorded-yet" } else { $evidenceStrictGateState })") | Out-Null
$arabicLines.Add("- Current Run Label: $(if ([string]::IsNullOrWhiteSpace($runLabel)) { "not-recorded-yet" } else { $runLabel })") | Out-Null
$arabicLines.Add("- Current Version: $(if ([string]::IsNullOrWhiteSpace($version)) { "not-recorded-yet" } else { $version })") | Out-Null
$arabicLines.Add("") | Out-Null
$arabicLines.Add("## $arabicHeadingShort") | Out-Null
$arabicLines.Add($arabicShortUpdateLine) | Out-Null
$arabicLines.Add("") | Out-Null
$arabicLines.Add("## $arabicHeadingHighlights") | Out-Null
foreach ($item in $topProgress) {
    $arabicLines.Add("- $item") | Out-Null
}
if ($topProgress.Count -eq 0) {
    $arabicLines.Add("- $arabicNone") | Out-Null
}
$arabicLines.Add("") | Out-Null
$arabicLines.Add("## $arabicHeadingNext") | Out-Null
foreach ($item in $topNext) {
    $arabicLines.Add("- $item") | Out-Null
}
if ($topNext.Count -eq 0) {
    $arabicLines.Add("- $arabicNone") | Out-Null
}

Set-Content -Path $englishBriefPath -Value ($englishLines -join "`r`n") -Encoding UTF8
Set-Content -Path $arabicBriefPath -Value ($arabicLines -join "`r`n") -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $englishBriefPath
}
else {
    Write-Host "Updated Lumina-OS shareable briefs:"
    Write-Host "English: $englishBriefPath"
    Write-Host "Arabic:  $arabicBriefPath"
}
