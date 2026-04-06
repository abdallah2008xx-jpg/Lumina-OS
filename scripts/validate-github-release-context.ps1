param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseManifestPath,
    [string]$Owner = "",
    [string]$Repo = "",
    [string]$Token = "",
    [switch]$AllowPublishedCandidate,
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

function Get-ConfigValue {
    param(
        [string]$Path,
        [string]$VariableName
    )

    if (-not (Test-Path $Path)) {
        return ""
    }

    $content = Get-Content -Raw $Path
    $pattern = "(?m)^" + [regex]::Escape($VariableName) + "=""([^""]*)"""
    $match = [regex]::Match($content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return ""
}

function Add-ValidationItem {
    param(
        [System.Collections.Generic.List[string]]$Bucket,
        [string]$Message
    )

    $Bucket.Add($Message) | Out-Null
}

function Resolve-RequiredPath {
    param(
        [string]$Label,
        [string]$Value,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Add-ValidationItem -Bucket $Errors -Message "$Label is missing."
        return ""
    }

    if (-not (Test-Path $Value)) {
        Add-ValidationItem -Bucket $Errors -Message "$Label not found: $Value"
        return ""
    }

    return (Resolve-Path $Value).Path
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$notes = [System.Collections.Generic.List[string]]::new()

$resolvedManifestPath = Resolve-RequiredPath -Label "Release manifest" -Value $ReleaseManifestPath -Errors $errors
if ([string]::IsNullOrWhiteSpace($resolvedManifestPath)) {
    throw "Release manifest could not be resolved."
}

$manifestContent = Get-Content -Raw $resolvedManifestPath
$releaseDir = Split-Path -Parent $resolvedManifestPath
$reportPath = Join-Path $releaseDir "github-release-context.md"
$validationReportPath = Resolve-RequiredPath -Label "Release validation report" -Value (Join-Path $releaseDir "release-validation.md") -Errors $errors
$currentCandidatePath = Resolve-RequiredPath -Label "Current release candidate" -Value (Join-Path $RepoRoot "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md") -Errors $errors

$version = Get-MetadataValue -Content $manifestContent -Label "Version"
$runLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"
$mode = Get-MetadataValue -Content $manifestContent -Label "Mode"
$installReportPath = Resolve-RequiredPath -Label "Install Report" -Value (Get-MetadataValue -Content $manifestContent -Label "Install Report") -Errors $errors
$installReportRunLabel = Get-MetadataValue -Content $manifestContent -Label "Install Report Run Label"
$installReportSelection = Get-MetadataValue -Content $manifestContent -Label "Install Report Selection"
$hardwareReportPath = Resolve-RequiredPath -Label "Hardware Report" -Value (Get-MetadataValue -Content $manifestContent -Label "Hardware Report") -Errors $errors
$hardwareReportRunLabel = Get-MetadataValue -Content $manifestContent -Label "Hardware Report Run Label"
$hardwareReportSelection = Get-MetadataValue -Content $manifestContent -Label "Hardware Report Selection"

$releaseConfigPath = Join-Path $RepoRoot "archiso-profile\airootfs\etc\ahmados-release.conf"
$resolvedOwner = if ([string]::IsNullOrWhiteSpace($Owner)) {
    Get-ConfigValue -Path $releaseConfigPath -VariableName "AHMADOS_GITHUB_OWNER"
}
else {
    $Owner
}

$resolvedRepo = if ([string]::IsNullOrWhiteSpace($Repo)) {
    Get-ConfigValue -Path $releaseConfigPath -VariableName "AHMADOS_GITHUB_REPO"
}
else {
    $Repo
}

if ([string]::IsNullOrWhiteSpace($resolvedOwner)) {
    Add-ValidationItem -Bucket $errors -Message "GitHub owner is missing."
}

if ([string]::IsNullOrWhiteSpace($resolvedRepo)) {
    Add-ValidationItem -Bucket $errors -Message "GitHub repo is missing."
}

$resolvedToken = ""
$tokenSource = ""
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $resolvedToken = $Token
    $tokenSource = "argument"
}
elseif (-not [string]::IsNullOrWhiteSpace($env:LUMINA_GITHUB_TOKEN)) {
    $resolvedToken = $env:LUMINA_GITHUB_TOKEN
    $tokenSource = "LUMINA_GITHUB_TOKEN"
}
elseif (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $resolvedToken = $env:GITHUB_TOKEN
    $tokenSource = "GITHUB_TOKEN"
}
else {
    Add-ValidationItem -Bucket $errors -Message "No GitHub token source is available."
}

if (-not [string]::IsNullOrWhiteSpace($resolvedToken)) {
    Add-ValidationItem -Bucket $notes -Message ("GitHub token source resolved from " + $tokenSource + ".")
}

$validationContent = if (-not [string]::IsNullOrWhiteSpace($validationReportPath)) { Get-Content -Raw $validationReportPath } else { "" }
$validationResult = Get-MetadataValue -Content $validationContent -Label "Result"
$validationRunLabel = Get-MetadataValue -Content $validationContent -Label "Run Label"
$installReportState = Get-MetadataValue -Content $validationContent -Label "Install Report Status"
$hardwareReportState = Get-MetadataValue -Content $validationContent -Label "Hardware Report Status"

if ($validationResult -ne "passed") {
    Add-ValidationItem -Bucket $errors -Message "Release validation result is not passed: $(if ([string]::IsNullOrWhiteSpace($validationResult)) { "not-recorded-yet" } else { $validationResult })"
}

if ([string]::IsNullOrWhiteSpace($installReportState) -or $installReportState -eq "not-recorded-yet") {
    Add-ValidationItem -Bucket $errors -Message "Install report status is missing from the release validation report."
}
else {
    Add-ValidationItem -Bucket $notes -Message "Install report status resolved as $installReportState."
}

if ([string]::IsNullOrWhiteSpace($hardwareReportState) -or $hardwareReportState -eq "not-recorded-yet") {
    Add-ValidationItem -Bucket $errors -Message "Hardware report status is missing from the release validation report."
}
else {
    Add-ValidationItem -Bucket $notes -Message "Hardware report status resolved as $hardwareReportState."
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($installReportRunLabel) -and
    $installReportRunLabel -ne $runLabel) {
    Add-ValidationItem -Bucket $warnings -Message "Install report Run Label does not match the release manifest."
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($hardwareReportRunLabel) -and
    $hardwareReportRunLabel -ne $runLabel) {
    Add-ValidationItem -Bucket $warnings -Message "Hardware report Run Label does not match the release manifest."
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($validationRunLabel) -and
    $validationRunLabel -ne $runLabel) {
    Add-ValidationItem -Bucket $errors -Message "Release validation report Run Label does not match the release manifest."
}

$candidateContent = if (-not [string]::IsNullOrWhiteSpace($currentCandidatePath)) { Get-Content -Raw $currentCandidatePath } else { "" }
$candidateState = Get-MetadataValue -Content $candidateContent -Label "Candidate State"
$candidateManifestPath = Get-MetadataValue -Content $candidateContent -Label "Release Manifest"
$candidateRunLabel = Get-MetadataValue -Content $candidateContent -Label "Run Label"
$candidateVersion = Get-MetadataValue -Content $candidateContent -Label "Version"

if ([string]::IsNullOrWhiteSpace($candidateState)) {
    Add-ValidationItem -Bucket $errors -Message "Current release candidate state is missing."
}
elseif ($candidateState -eq "ready-to-publish") {
    Add-ValidationItem -Bucket $notes -Message "Current release candidate is ready to publish."
}
elseif ($candidateState -eq "published" -and $AllowPublishedCandidate.IsPresent) {
    Add-ValidationItem -Bucket $warnings -Message "Current release candidate is already published; proceeding because -AllowPublishedCandidate was provided."
}
else {
    $expectedState = if ($AllowPublishedCandidate.IsPresent) { "ready-to-publish or published" } else { "ready-to-publish" }
    Add-ValidationItem -Bucket $errors -Message "Current release candidate state is not ${expectedState}: $candidateState"
}

if (-not [string]::IsNullOrWhiteSpace($candidateManifestPath)) {
    $resolvedCandidateManifestPath = if (Test-Path $candidateManifestPath) { (Resolve-Path $candidateManifestPath).Path } else { $candidateManifestPath }
    if ($resolvedCandidateManifestPath -ne $resolvedManifestPath) {
        Add-ValidationItem -Bucket $errors -Message "Current release candidate points to a different release manifest."
    }
}
else {
    Add-ValidationItem -Bucket $errors -Message "Current release candidate does not record a release manifest path."
}

if (-not [string]::IsNullOrWhiteSpace($runLabel) -and
    -not [string]::IsNullOrWhiteSpace($candidateRunLabel) -and
    $candidateRunLabel -ne $runLabel) {
    Add-ValidationItem -Bucket $errors -Message "Current release candidate Run Label does not match the release manifest."
}

if (-not [string]::IsNullOrWhiteSpace($version) -and
    -not [string]::IsNullOrWhiteSpace($candidateVersion) -and
    $candidateVersion -ne $version) {
    Add-ValidationItem -Bucket $errors -Message "Current release candidate Version does not match the release manifest."
}

$overallState = if ($errors.Count -gt 0) {
    "fail"
}
elseif ($warnings.Count -gt 0) {
    "warning"
}
else {
    "pass"
}

$report = @"
# Lumina-OS GitHub Release Context Report

- Checked At: $(Get-Date -Format s)
- Overall State: $overallState
- Version: $(if ([string]::IsNullOrWhiteSpace($version)) { "not-recorded-yet" } else { $version })
- Mode: $(if ([string]::IsNullOrWhiteSpace($mode)) { "not-recorded-yet" } else { $mode })
- Run Label: $(if ([string]::IsNullOrWhiteSpace($runLabel)) { "not-recorded-yet" } else { $runLabel })
- GitHub Repository: $(if ([string]::IsNullOrWhiteSpace($resolvedOwner) -or [string]::IsNullOrWhiteSpace($resolvedRepo)) { "not-recorded-yet" } else { "$resolvedOwner/$resolvedRepo" })
- Token Source: $(if ([string]::IsNullOrWhiteSpace($tokenSource)) { "not-recorded-yet" } else { $tokenSource })
- Install Report: $(if ([string]::IsNullOrWhiteSpace($installReportPath)) { "not-recorded-yet" } else { $installReportPath })
- Install Report Status: $(if ([string]::IsNullOrWhiteSpace($installReportState)) { "not-recorded-yet" } else { $installReportState })
- Install Report Run Label: $(if ([string]::IsNullOrWhiteSpace($installReportRunLabel)) { "not-recorded-yet" } else { $installReportRunLabel })
- Install Report Selection: $(if ([string]::IsNullOrWhiteSpace($installReportSelection)) { "not-recorded-yet" } else { $installReportSelection })
- Hardware Report: $(if ([string]::IsNullOrWhiteSpace($hardwareReportPath)) { "not-recorded-yet" } else { $hardwareReportPath })
- Hardware Report Status: $(if ([string]::IsNullOrWhiteSpace($hardwareReportState)) { "not-recorded-yet" } else { $hardwareReportState })
- Hardware Report Run Label: $(if ([string]::IsNullOrWhiteSpace($hardwareReportRunLabel)) { "not-recorded-yet" } else { $hardwareReportRunLabel })
- Hardware Report Selection: $(if ([string]::IsNullOrWhiteSpace($hardwareReportSelection)) { "not-recorded-yet" } else { $hardwareReportSelection })
- Release Manifest: $resolvedManifestPath
- Release Validation Report: $(if ([string]::IsNullOrWhiteSpace($validationReportPath)) { "not-recorded-yet" } else { $validationReportPath })
- Current Release Candidate: $(if ([string]::IsNullOrWhiteSpace($currentCandidatePath)) { "not-recorded-yet" } else { $currentCandidatePath })

## Notes
$(if ($notes.Count -gt 0) { ($notes | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" })

## Warnings
$(if ($warnings.Count -gt 0) { ($warnings | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" })

## Errors
$(if ($errors.Count -gt 0) { ($errors | ForEach-Object { "- $_" }) -join "`r`n" } else { "- none" })
"@

Set-Content -Path $reportPath -Value $report -Encoding UTF8

if ($errors.Count -gt 0) {
    throw "GitHub release context validation failed. See: $reportPath"
}

if ($OutputPathOnly) {
    Write-Output $reportPath
}
else {
    Write-Host "Validated Lumina-OS GitHub release context:"
    Write-Host "Report: $reportPath"
}
