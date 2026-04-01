param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$packageProvidedPermissionTargets = @(
    "/etc/shadow"
)

function Add-Error {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Add-Warning {
    param([string]$Message)
    $script:warnings.Add($Message)
}

function Assert-PathExists {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Error "Missing required path: $RelativePath"
    }
}

function Test-JsonFile {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Error "Cannot parse missing JSON file: $RelativePath"
        return
    }

    try {
        Get-Content -Raw $fullPath | ConvertFrom-Json | Out-Null
    }
    catch {
        Add-Error "Invalid JSON in: $RelativePath"
    }
}

$requiredPaths = @(
    "archiso-profile\profiledef.sh",
    "archiso-profile\packages.x86_64",
    "archiso-profile\build-variants\sddm\stable-autologin.conf",
    "archiso-profile\build-variants\sddm\manual-login.conf",
    "archiso-profile\airootfs\etc\sddm.conf.d\theme.conf",
    "archiso-profile\airootfs\etc\ahmados-release.conf",
    "archiso-profile\airootfs\usr\share\sddm\themes\ahmados\Main.qml",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.classic\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.minimal\manifest.json",
    "archiso-profile\airootfs\usr\share\color-schemes\AhmadOS.colors",
    "archiso-profile\airootfs\usr\share\color-schemes\AhmadOSNight.colors",
    "archiso-profile\airootfs\usr\share\ahmados\welcome\Main.qml",
    "archiso-profile\airootfs\usr\share\ahmados\update-center\Main.qml",
    "archiso-profile\airootfs\usr\share\ahmados\update-center\releases.json",
    "archiso-profile\airootfs\usr\local\bin\ahmados-export-diagnostics",
    "archiso-profile\airootfs\usr\local\bin\ahmados-run-smoke-checks",
    "archiso-profile\airootfs\usr\local\bin\ahmados-firstboot",
    "archiso-profile\airootfs\usr\local\bin\ahmados-open-firstboot-report",
    "archiso-profile\airootfs\usr\local\bin\ahmados-refresh-release-metadata",
    "archiso-profile\airootfs\usr\local\bin\ahmados-update-center",
    "archiso-profile\airootfs\usr\local\bin\ahmados-welcome",
    "archiso-profile\airootfs\home\live\.local\bin\ahmados-apply-session-defaults",
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-firstboot.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-export-diagnostics.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-firstboot-report.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-run-smoke-checks.desktop",
    "scripts\build-iso-arch.sh",
    "scripts\build-iso.ps1",
    "scripts\bootstrap-arch-build-env.sh",
    "scripts\validate-profile.sh",
    "scripts\write-build-manifest.sh",
    "scripts\new-vm-test-report.ps1",
    "scripts\new-test-session.ps1",
    "scripts\start-vm-test-cycle.ps1",
    "scripts\finish-vm-test-cycle.ps1",
    "scripts\audit-test-session.ps1",
    "scripts\sync-test-blockers.ps1",
    "scripts\sync-readiness-status.ps1",
    "scripts\sync-validation-matrix.ps1",
    "scripts\import-diagnostics-bundle.ps1",
    "scripts\prepare-release-package.ps1",
    "status\builds\README.md",
    "status\vm-tests\README.md",
    "status\test-sessions\README.md",
    "status\test-session-audits\README.md",
    "status\diagnostics\README.md",
    "status\releases\README.md",
    "status\blockers\README.md",
    "status\blockers\CURRENT-BLOCKERS.md",
    "status\readiness\README.md",
    "status\readiness\CURRENT-READINESS.md",
    "status\validation-matrix\README.md",
    "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md"
)

foreach ($relativePath in $requiredPaths) {
    Assert-PathExists $relativePath
}

$jsonFiles = @(
    "archiso-profile\airootfs\usr\share\ahmados\update-center\releases.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.classic\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.minimal\manifest.json"
)

foreach ($jsonFile in $jsonFiles) {
    Test-JsonFile $jsonFile
}

$packageFile = Join-Path $RepoRoot "archiso-profile\packages.x86_64"
if (Test-Path $packageFile) {
    $packages = Get-Content $packageFile |
        Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") } |
        ForEach-Object { $_.Trim() }

    foreach ($requiredPackage in @("curl", "qt6-declarative", "qt6-svg", "systemsettings", "plasma-x11-session")) {
        if ($packages -notcontains $requiredPackage) {
            Add-Error "Missing expected package in packages.x86_64: $requiredPackage"
        }
    }
}

$wallpaperPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\share\ahmados\wallpapers"
if (Test-Path $wallpaperPath) {
    $wallpapers = Get-ChildItem $wallpaperPath -Filter *.svg -ErrorAction SilentlyContinue
    if ($wallpapers.Count -lt 3) {
        Add-Error "Expected at least three Lumina-OS wallpapers, found $($wallpapers.Count)."
    }
}
else {
    Add-Error "Missing wallpaper directory: archiso-profile\\airootfs\\usr\\share\\ahmados\\wallpapers"
}

$themeConfPath = Join-Path $RepoRoot "archiso-profile\airootfs\etc\sddm.conf.d\theme.conf"
if (Test-Path $themeConfPath) {
    $themeConf = Get-Content -Raw $themeConfPath
    if ($themeConf -match 'Current=(?<theme>[^\r\n]+)') {
        $themeName = $Matches.theme.Trim()
        $themeMainQml = Join-Path $RepoRoot ("archiso-profile\airootfs\usr\share\sddm\themes\" + $themeName + "\Main.qml")
        if (-not (Test-Path $themeMainQml)) {
            Add-Error "SDDM theme points to missing Main.qml: $themeName"
        }
    }
    else {
        Add-Error "Could not find Current=... in theme.conf"
    }
}

$profiledefPath = Join-Path $RepoRoot "archiso-profile\profiledef.sh"
if (Test-Path $profiledefPath) {
    $profiledef = Get-Content -Raw $profiledefPath
    $matches = [regex]::Matches($profiledef, '\["(?<path>/[^"]+)"\]="[^"]+"')

    foreach ($match in $matches) {
        $unixPath = $match.Groups["path"].Value

        if ($packageProvidedPermissionTargets -contains $unixPath) {
            continue
        }

        $trimmedPath = $unixPath.TrimStart("/")
        $windowsPath = $trimmedPath -replace '/', '\'
        $expectedPath = Join-Path $RepoRoot ("archiso-profile\airootfs\" + $windowsPath)

        if (-not (Test-Path $expectedPath)) {
            Add-Error "profiledef.sh references a missing permission target: $unixPath"
        }
    }
}

$releaseConfigPath = Join-Path $RepoRoot "archiso-profile\airootfs\etc\ahmados-release.conf"
if (Test-Path $releaseConfigPath) {
    $releaseConfig = Get-Content -Raw $releaseConfigPath
    foreach ($requiredVariable in @("AHMADOS_RELEASES_SOURCE", "AHMADOS_GITHUB_OWNER", "AHMADOS_GITHUB_REPO", "AHMADOS_INSTALLED_VERSION")) {
        if ($releaseConfig -notmatch [regex]::Escape($requiredVariable)) {
            Add-Error "Missing expected release variable in etc/ahmados-release.conf: $requiredVariable"
        }
    }
}

$firstbootPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-firstboot"
if (Test-Path $firstbootPath) {
    $firstbootContent = Get-Content -Raw $firstbootPath
    if ($firstbootContent -match "placeholder") {
        Add-Error "ahmados-firstboot is still a placeholder."
    }
    if ($firstbootContent -notmatch "firstboot-report") {
        Add-Warning "ahmados-firstboot does not appear to write a firstboot report."
    }
}

$exportDiagnosticsPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-export-diagnostics"
if (Test-Path $exportDiagnosticsPath) {
    $exportContent = Get-Content -Raw $exportDiagnosticsPath
    if ($exportContent -notmatch "diagnostics") {
        Add-Warning "ahmados-export-diagnostics may not be writing a diagnostics bundle."
    }
    if ($exportContent -notmatch "smoke-check-report") {
        Add-Warning "ahmados-export-diagnostics does not appear to include the smoke-check report."
    }
}

$smokeCheckPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-run-smoke-checks"
if (Test-Path $smokeCheckPath) {
    $smokeContent = Get-Content -Raw $smokeCheckPath
    if ($smokeContent -notmatch "Smoke Check Report") {
        Add-Warning "ahmados-run-smoke-checks may not be writing the expected report."
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host " - $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "Lumina-OS profile validation failed." -ForegroundColor Red
    foreach ($errorItem in $errors) {
        Write-Host " - $errorItem" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Lumina-OS profile validation passed." -ForegroundColor Green
