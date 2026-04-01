param(
    [Parameter(Mandatory = $true)]
    [string]$RunId,
    [string]$ArtifactName = "",
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "",
    [string]$Owner = "abdallah2008xx-jpg",
    [string]$Repo = "Lumina-OS",
    [string]$Token = "",
    [switch]$OutputPathOnly,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-SafeSegment {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unknown"
    }

    $safe = $Value.ToLowerInvariant()
    $safe = [regex]::Replace($safe, "[^a-z0-9\.-]+", "-")
    $safe = $safe.Trim("-")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "unknown"
    }

    return $safe
}

function Get-AvailableArtifactNames {
    param([object[]]$Artifacts)

    $names = @($Artifacts | ForEach-Object { $_.name } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) {
        return "none"
    }

    return ($names -join ", ")
}

$resolvedToken = if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $Token.Trim()
}
elseif (-not [string]::IsNullOrWhiteSpace($env:LUMINA_GITHUB_TOKEN)) {
    $env:LUMINA_GITHUB_TOKEN
}
elseif (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $env:GITHUB_TOKEN
}
else {
    ""
}

if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
    throw "GitHub artifact download requires a token. Set LUMINA_GITHUB_TOKEN or GITHUB_TOKEN, or pass -Token explicitly."
}

$headers = @{
    "Accept" = "application/vnd.github+json"
    "Authorization" = "Bearer $resolvedToken"
    "X-GitHub-Api-Version" = "2026-03-10"
    "User-Agent" = "Lumina-OS Artifact Downloader"
}

$artifactsEndpoint = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId/artifacts?per_page=100"
$artifactsResponse = Invoke-RestMethod -Headers $headers -Uri $artifactsEndpoint -Method Get
$allArtifacts = @($artifactsResponse.artifacts)
$artifact = $null

if (-not [string]::IsNullOrWhiteSpace($ArtifactName)) {
    $artifact = $allArtifacts | Where-Object { $_.name -eq $ArtifactName.Trim() } | Select-Object -First 1

    if ($null -eq $artifact) {
        $availableNames = Get-AvailableArtifactNames -Artifacts $allArtifacts
        throw "Could not find artifact '$ArtifactName' for run '$RunId' in $Owner/$Repo. Available artifacts: $availableNames"
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($Mode)) {
    $modePrefix = "lumina-os-$Mode-"
    $modeMatches = @($allArtifacts | Where-Object { $_.name -like ($modePrefix + "*") })

    if ($modeMatches.Count -eq 0) {
        $availableNames = Get-AvailableArtifactNames -Artifacts $allArtifacts
        throw "Could not find a Lumina-OS artifact for mode '$Mode' in run '$RunId'. Available artifacts: $availableNames"
    }

    if ($modeMatches.Count -gt 1) {
        $matchedNames = Get-AvailableArtifactNames -Artifacts $modeMatches
        throw "Run '$RunId' returned multiple Lumina-OS artifacts for mode '$Mode'. Pass -ArtifactName explicitly. Matching artifacts: $matchedNames"
    }

    $artifact = $modeMatches[0]
}
elseif ($allArtifacts.Count -eq 1) {
    $artifact = $allArtifacts[0]
}
else {
    $availableNames = Get-AvailableArtifactNames -Artifacts $allArtifacts
    throw "Provide -ArtifactName or -Mode when the run contains multiple artifacts. Available artifacts: $availableNames"
}

if ($null -eq $artifact) {
    throw "Could not resolve a downloadable artifact for run '$RunId' in $Owner/$Repo."
}

if ($artifact.expired) {
    throw "Artifact '$($artifact.name)' for run '$RunId' has expired."
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeArtifactName = Get-SafeSegment $artifact.name
$downloadDir = Join-Path $RepoRoot ("build\downloaded-artifacts\" + $dateStamp)
$downloadPath = Join-Path $downloadDir ($timeStamp + "-" + $safeArtifactName + ".zip")
$summaryDir = Join-Path $RepoRoot ("status\build-handoffs\" + $dateStamp)
$summaryPath = Join-Path $summaryDir ($timeStamp + "-download-" + $safeArtifactName + ".md")

New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
New-Item -ItemType Directory -Force -Path $summaryDir | Out-Null

Invoke-WebRequest -Headers $headers -Uri $artifact.archive_download_url -OutFile $downloadPath

$downloadedItem = Get-Item $downloadPath
$summaryContent = @"
# Lumina-OS GitHub Actions Artifact Download

- Downloaded At: $(Get-Date -Format s)
- Repository: $Owner/$Repo
- Run Id: $RunId
- Requested Artifact Name: $(if ([string]::IsNullOrWhiteSpace($ArtifactName)) { 'auto-resolved' } else { $ArtifactName.Trim() })
- Requested Mode: $(if ([string]::IsNullOrWhiteSpace($Mode)) { 'not-specified' } else { $Mode })
- Resolved Artifact Name: $($artifact.name)
- Artifact Id: $($artifact.id)
- Download Path: $downloadPath
- Size Bytes: $($downloadedItem.Length)

## Next Step
- import this zip with scripts/import-github-actions-artifact.ps1
- or start the VM cycle directly with scripts/start-github-actions-vm-cycle.ps1
"@

Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8

if ($OutputPathOnly) {
    Write-Output $downloadPath
}
else {
    Write-Host "Downloaded Lumina-OS GitHub Actions artifact:"
    Write-Host "Artifact: $downloadPath"
    Write-Host "Summary:  $summaryPath"
}
