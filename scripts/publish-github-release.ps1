param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseManifestPath,
    [string]$Owner = "",
    [string]$Repo = "",
    [string]$Token = "",
    [string]$TargetCommitish = "main",
    [switch]$Prerelease,
    [switch]$Ready,
    [switch]$AllowAttentionState,
    [switch]$SkipValidationGate,
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

function Resolve-RequiredPath {
    param(
        [string]$Label,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Release manifest is missing a required value: $Label"
    }

    if (-not (Test-Path $Value)) {
        throw "$Label not found: $Value"
    }

    return (Resolve-Path $Value).Path
}

function Get-ReleaseHeaders {
    param([string]$ResolvedToken)

    return @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $ResolvedToken"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent" = "Lumina-OS-Release-Script"
    }
}

function Upload-ReleaseAsset {
    param(
        [string]$UploadBaseUrl,
        [string]$AssetPath,
        [hashtable]$Headers
    )

    $assetName = [System.IO.Path]::GetFileName($AssetPath)
    $encodedName = [System.Uri]::EscapeDataString($assetName)
    $uploadUrl = $UploadBaseUrl + "?name=" + $encodedName

    return Invoke-RestMethod `
        -Method Post `
        -Uri $uploadUrl `
        -Headers $Headers `
        -ContentType "application/octet-stream" `
        -InFile $AssetPath
}

$resolvedManifestPath = Resolve-RequiredPath -Label "Release manifest" -Value $ReleaseManifestPath
$manifestContent = Get-Content -Raw $resolvedManifestPath
$releaseDir = Split-Path -Parent $resolvedManifestPath
$validationReportPath = Join-Path $releaseDir "release-validation.md"
$syncCandidateScript = Join-Path $PSScriptRoot "sync-release-candidate-status.ps1"

if (-not (Test-Path $syncCandidateScript)) {
    throw "Release candidate sync script is missing: $syncCandidateScript"
}

if (-not $SkipValidationGate.IsPresent) {
    $validatorPath = Join-Path $PSScriptRoot "validate-release-package.ps1"
    if (-not (Test-Path $validatorPath)) {
        throw "Validation gate script is missing: $validatorPath"
    }

    $validationArgs = @{
        ReleaseManifestPath = $resolvedManifestPath
        RepoRoot = $RepoRoot
    }

    if ($AllowAttentionState.IsPresent) {
        $validationArgs["AllowAttentionState"] = $true
    }

    & $validatorPath @validationArgs | Out-Null
}

$version = Get-MetadataValue -Content $manifestContent -Label "Version"
$isoPath = Resolve-RequiredPath -Label "ISO path" -Value (Get-MetadataValue -Content $manifestContent -Label "ISO Path")
$checksumPath = Resolve-RequiredPath -Label "Checksum file" -Value (Get-MetadataValue -Content $manifestContent -Label "Checksum File")
$releaseNotesPath = Resolve-RequiredPath -Label "Release notes" -Value (Get-MetadataValue -Content $manifestContent -Label "Release Notes")
$mode = Get-MetadataValue -Content $manifestContent -Label "Mode"
$runLabel = Get-MetadataValue -Content $manifestContent -Label "Run Label"

if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Release manifest is missing the Version field."
}

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

if ([string]::IsNullOrWhiteSpace($resolvedOwner) -or [string]::IsNullOrWhiteSpace($resolvedRepo)) {
    throw "GitHub owner/repo could not be resolved. Pass -Owner and -Repo or configure etc/ahmados-release.conf."
}

$resolvedToken = if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $Token
}
elseif (-not [string]::IsNullOrWhiteSpace($env:LUMINA_GITHUB_TOKEN)) {
    $env:LUMINA_GITHUB_TOKEN
}
elseif (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $env:GITHUB_TOKEN
}
else {
    throw "No GitHub token found. Set LUMINA_GITHUB_TOKEN or GITHUB_TOKEN, or pass -Token."
}

$releaseNotes = Get-Content -Raw $releaseNotesPath
$tagName = if ($version.StartsWith("v")) { $version } else { "v$version" }
$releaseName = "Lumina-OS $version"
$draftState = -not $Ready.IsPresent
$headers = Get-ReleaseHeaders -ResolvedToken $resolvedToken
$releaseUri = "https://api.github.com/repos/$resolvedOwner/$resolvedRepo/releases"

$createPayload = @{
    tag_name = $tagName
    target_commitish = $TargetCommitish
    name = $releaseName
    body = $releaseNotes
    draft = $draftState
    prerelease = $Prerelease.IsPresent
    generate_release_notes = $false
} | ConvertTo-Json -Depth 6

try {
    $createdRelease = Invoke-RestMethod `
        -Method Post `
        -Uri $releaseUri `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $createPayload
}
catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails.Message) {
        $message = $_.ErrorDetails.Message
    }

    throw "GitHub release creation failed: $message"
}

$uploadBaseUrl = ($createdRelease.upload_url -replace "\{\?name,label\}", "")
$isoUpload = Upload-ReleaseAsset -UploadBaseUrl $uploadBaseUrl -AssetPath $isoPath -Headers $headers
$checksumUpload = Upload-ReleaseAsset -UploadBaseUrl $uploadBaseUrl -AssetPath $checksumPath -Headers $headers

$publishRecordPath = Join-Path $releaseDir "github-release-publish.md"
$publishRecord = @"
# Lumina-OS GitHub Release Publish Record

- Published At: $(Get-Date -Format s)
- Version: $version
- Tag: $tagName
- Draft: $draftState
- Prerelease: $($Prerelease.IsPresent)
- Mode: $mode
- Run Label: $(if ([string]::IsNullOrWhiteSpace($runLabel)) { "not-recorded-yet" } else { $runLabel })
- Repository: $resolvedOwner/$resolvedRepo
- Target Commitish: $TargetCommitish
- Release Manifest: $resolvedManifestPath
- Validation Report: $(if (Test-Path $validationReportPath) { $validationReportPath } else { "not-recorded-yet" })
- Release Notes: $releaseNotesPath
- Release URL: $($createdRelease.html_url)
- Release ID: $($createdRelease.id)

## Uploaded Assets
- ISO: $($isoUpload.browser_download_url)
- Checksum: $($checksumUpload.browser_download_url)

## Notes
- This record was created by `scripts/publish-github-release.ps1`.
- Keep it with the prepared release package so publish history stays linked to the tested ISO evidence.
"@

Set-Content -Path $publishRecordPath -Value $publishRecord -Encoding UTF8

$candidateSummaryPath = & $syncCandidateScript `
    -ReleaseManifestPath $resolvedManifestPath `
    -ValidationReportPath $validationReportPath `
    -PublishRecordPath $publishRecordPath `
    -RepoRoot $RepoRoot `
    -OutputPathOnly

if ($OutputPathOnly) {
    Write-Output $publishRecordPath
}
else {
    Write-Host "Published Lumina-OS GitHub release:"
    Write-Host "Release: $($createdRelease.html_url)"
    Write-Host "Publish Record: $publishRecordPath"
    if ($candidateSummaryPath) {
        Write-Host "Candidate Summary: $candidateSummaryPath"
    }
}
