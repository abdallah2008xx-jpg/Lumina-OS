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

function Find-ExistingDownloadedArtifact {
    param(
        [string]$SearchRoot,
        [string]$ArtifactName,
        [long]$ExpectedSizeBytes
    )

    if (-not (Test-Path $SearchRoot)) {
        return $null
    }

    return Get-ChildItem -Path $SearchRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq (Get-SafeSegment $ArtifactName) + ".zip" -or
            $_.Name -like ("*" + (Get-SafeSegment $ArtifactName) + ".zip")
        } |
        Where-Object {
            if ($ExpectedSizeBytes -le 0) {
                return $true
            }

            return $_.Length -eq $ExpectedSizeBytes
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Find-PartialDownloadedArtifact {
    param(
        [string]$SearchRoot,
        [string]$ArtifactName,
        [long]$ExpectedSizeBytes
    )

    if (-not (Test-Path $SearchRoot)) {
        return $null
    }

    return Get-ChildItem -Path $SearchRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq (Get-SafeSegment $ArtifactName) + ".zip" -or
            $_.Name -like ("*" + (Get-SafeSegment $ArtifactName) + ".zip")
        } |
        Where-Object {
            if ($ExpectedSizeBytes -le 0) {
                return $_.Length -gt 0
            }

            return $_.Length -gt 0 -and $_.Length -lt $ExpectedSizeBytes
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Remove-ZeroByteDownloadedArtifacts {
    param(
        [string]$SearchRoot,
        [string]$ArtifactName
    )

    if (-not (Test-Path $SearchRoot)) {
        return
    }

    Get-ChildItem -Path $SearchRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.Name -eq (Get-SafeSegment $ArtifactName) + ".zip" -or
            $_.Name -like ("*" + (Get-SafeSegment $ArtifactName) + ".zip")) -and
            $_.Length -eq 0
        } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

function Get-GitCredentialPassword {
    param(
        [string]$GitHost,
        [string]$Username = ""
    )

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return ""
    }

    $requestLines = @(
        "protocol=https",
        "host=$GitHost"
    )

    if (-not [string]::IsNullOrWhiteSpace($Username)) {
        $requestLines += "username=$Username"
    }

    $request = ($requestLines -join "`n") + "`n`n"
    $credentialOutput = $request | & $gitCommand.Source credential fill 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($credentialOutput)) {
        return ""
    }

    $passwordLine = $credentialOutput -split "`r?`n" | Where-Object { $_ -like "password=*" } | Select-Object -First 1
    if ($null -eq $passwordLine) {
        return ""
    }

    return ($passwordLine -replace "^password=", "").Trim()
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
    $fromGitCredential = Get-GitCredentialPassword -GitHost "github.com" -Username $Owner
    if (-not [string]::IsNullOrWhiteSpace($fromGitCredential)) {
        $fromGitCredential
    }
    else {
        Get-GitCredentialPassword -GitHost "github.com"
    }
}

if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
    throw "GitHub artifact download requires a token. Set LUMINA_GITHUB_TOKEN or GITHUB_TOKEN, pass -Token explicitly, or make sure Git has a usable github.com credential."
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
$downloadState = "downloaded-new"

New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
New-Item -ItemType Directory -Force -Path $summaryDir | Out-Null

Remove-ZeroByteDownloadedArtifacts -SearchRoot (Join-Path $RepoRoot "build\downloaded-artifacts") -ArtifactName $artifact.name
$existingArtifact = Find-ExistingDownloadedArtifact -SearchRoot (Join-Path $RepoRoot "build\downloaded-artifacts") -ArtifactName $artifact.name -ExpectedSizeBytes $artifact.size_in_bytes
if ($existingArtifact) {
    $downloadPath = $existingArtifact.FullName
    $downloadState = "reused-existing"
}
else {
    $partialArtifact = Find-PartialDownloadedArtifact -SearchRoot (Join-Path $RepoRoot "build\downloaded-artifacts") -ArtifactName $artifact.name -ExpectedSizeBytes $artifact.size_in_bytes
    if ($partialArtifact) {
        $downloadPath = $partialArtifact.FullName
        $downloadState = "resumed-partial"
    }

    $curlCommand = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($null -ne $curlCommand) {
        $curlArgs = @(
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--header", "Accept: application/vnd.github+json",
            "--header", "Authorization: Bearer $resolvedToken",
            "--header", "X-GitHub-Api-Version: 2026-03-10",
            "--header", "User-Agent: Lumina-OS Artifact Downloader"
        )

        if ((Test-Path $downloadPath) -and ((Get-Item $downloadPath).Length -gt 0)) {
            $curlArgs += @("-C", "-")
        }

        $curlArgs += @(
            "--output", $downloadPath,
            $artifact.archive_download_url
        )

        & $curlCommand.Source @curlArgs
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed while downloading artifact '$($artifact.name)'."
        }
    }
    else {
        if (Test-Path $downloadPath) {
            Remove-Item -LiteralPath $downloadPath -Force
        }

        Invoke-WebRequest -Headers $headers -Uri $artifact.archive_download_url -OutFile $downloadPath
    }
}

$downloadedItem = Get-Item $downloadPath
$expectedSizeBytes = [int64]$artifact.size_in_bytes
if ($expectedSizeBytes -gt 0 -and $downloadedItem.Length -lt $expectedSizeBytes) {
    throw "Artifact download is incomplete. Expected at least $expectedSizeBytes bytes but found $($downloadedItem.Length). Re-run the command to resume."
}

$summaryContent = @"
# Lumina-OS GitHub Actions Artifact Download

- Downloaded At: $(Get-Date -Format s)
- Repository: $Owner/$Repo
- Run Id: $RunId
- Requested Artifact Name: $(if ([string]::IsNullOrWhiteSpace($ArtifactName)) { 'auto-resolved' } else { $ArtifactName.Trim() })
- Requested Mode: $(if ([string]::IsNullOrWhiteSpace($Mode)) { 'not-specified' } else { $Mode })
- Resolved Artifact Name: $($artifact.name)
- Artifact Id: $($artifact.id)
- Download State: $downloadState
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
