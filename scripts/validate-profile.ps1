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
    "archiso-profile\airootfs\etc\pacman.d\mirrorlist",
    "archiso-profile\airootfs\etc\sddm.conf.d\theme.conf",
    "archiso-profile\airootfs\etc\ahmados-release.conf",
    "archiso-profile\airootfs\usr\share\sddm\themes\ahmados\Main.qml",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.classic\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.minimal\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\desktoptheme\LuminaGlass\metadata.json",
    "archiso-profile\airootfs\usr\share\plasma\desktoptheme\LuminaGlass\plasmarc",
    "archiso-profile\airootfs\usr\share\plasma\desktoptheme\LuminaGlass\widgets\panel-background.svg",
    "archiso-profile\airootfs\usr\share\plasma\desktoptheme\LuminaGlass\widgets\tasks.svg",
    "archiso-profile\airootfs\usr\share\color-schemes\AhmadOS.colors",
    "archiso-profile\airootfs\usr\share\color-schemes\AhmadOSNight.colors",
    "archiso-profile\airootfs\usr\share\ahmados\welcome\Main.qml",
    "archiso-profile\airootfs\usr\share\ahmados\update-center\Main.qml",
    "archiso-profile\airootfs\usr\share\ahmados\update-center\releases.json",
    "archiso-profile\airootfs\usr\local\bin\ahmados-export-diagnostics",
    "archiso-profile\airootfs\usr\local\bin\ahmados-apply-session-defaults",
    "archiso-profile\airootfs\usr\local\bin\ahmados-vm-display-prep",
    "archiso-profile\airootfs\usr\local\bin\ahmados-vm-guest-services",
    "archiso-profile\airootfs\usr\local\bin\ahmados-refresh-update-markers",
    "archiso-profile\airootfs\usr\local\bin\ahmados-finalize-install",
    "archiso-profile\airootfs\usr\local\bin\ahmados-installer",
    "archiso-profile\airootfs\usr\local\bin\ahmados-run-smoke-checks",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-compat-check",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-vm-lab",
    "archiso-profile\airootfs\usr\local\bin\ahmados-firstboot",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-apps",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-app-assistant",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-profile-assistant",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-profile-runbook",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-bootstrap",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-state",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-mark",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-recipe",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-hub",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-action-pack",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-next-action",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-vm-template",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-vm-creation-starter",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-vm-postcreate",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-app-install-starter",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-workflow-proof-pass",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-launch-broker",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-guest-agent-pack",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-vm-warm-start",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-launch-results-sync",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-launch-session",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-guest-onboarding",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-app-registration",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-registered-app-launch",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-app-launcher-pack",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-app-surfaces",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-registered-app-picker",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-apps-catalog",
    "archiso-profile\airootfs\usr\local\bin\ahmados-windows-apps-prep",
    "archiso-profile\airootfs\usr\local\bin\ahmados-capture-screenshot",
    "archiso-profile\airootfs\usr\local\bin\ahmados-open-firstboot-report",
    "archiso-profile\airootfs\usr\local\bin\ahmados-refresh-release-metadata",
    "archiso-profile\airootfs\usr\local\bin\ahmados-update-center",
    "archiso-profile\airootfs\usr\local\bin\ahmados-welcome",
    "archiso-profile\airootfs\usr\local\bin\lumina-capture-screenshot",
    "archiso-profile\airootfs\usr\local\bin\lumina-apply-session-defaults",
    "archiso-profile\airootfs\usr\local\bin\lumina-vm-display-prep",
    "archiso-profile\airootfs\usr\local\bin\lumina-vm-guest-services",
    "archiso-profile\airootfs\usr\local\bin\lumina-refresh-update-markers",
    "archiso-profile\airootfs\usr\local\bin\lumina-export-diagnostics",
    "archiso-profile\airootfs\usr\local\bin\lumina-finalize-install",
    "archiso-profile\airootfs\usr\local\bin\lumina-installer",
    "archiso-profile\airootfs\usr\local\bin\lumina-run-smoke-checks",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-compat-check",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-vm-lab",
    "archiso-profile\airootfs\usr\local\bin\lumina-firstboot",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-apps",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-app-assistant",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-profile-assistant",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-profile-runbook",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-bootstrap",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-state",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-mark",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-recipe",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-hub",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-action-pack",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-next-action",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-vm-template",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-vm-creation-starter",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-vm-postcreate",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-app-install-starter",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-workflow-proof-pass",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-launch-broker",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-guest-agent-pack",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-vm-warm-start",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-launch-results-sync",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-launch-session",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-guest-onboarding",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-app-registration",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-registered-app-launch",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-app-launcher-pack",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-app-surfaces",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-registered-app-picker",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-apps-catalog",
    "archiso-profile\airootfs\usr\local\bin\lumina-windows-apps-prep",
    "archiso-profile\airootfs\usr\local\bin\lumina-open-firstboot-report",
    "archiso-profile\airootfs\usr\local\bin\lumina-refresh-release-metadata",
    "archiso-profile\airootfs\usr\local\bin\lumina-update-center",
    "archiso-profile\airootfs\usr\local\bin\lumina-welcome",
    "archiso-profile\airootfs\home\live\.local\bin\ahmados-apply-session-defaults",
    "archiso-profile\airootfs\home\live\.local\bin\lumina-apply-session-defaults",
    "archiso-profile\airootfs\home\live\.config\plasmarc",
    "archiso-profile\airootfs\home\live\.config\mimeapps.list",
    "archiso-profile\airootfs\usr\local\lib\ahmados-session-context.sh",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\catalog.tsv",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\profiles.tsv",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\manifests\adobe-creator.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\manifests\office-productivity.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\manifests\studio-audio.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\manifests\gaming-launchers.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\manifests\restricted-gaming.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\recipes\adobe-creator.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\recipes\office-productivity.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\recipes\studio-audio.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\recipes\gaming-launchers.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\recipes\restricted-gaming.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\vm-templates\adobe-creator.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\vm-templates\office-productivity.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\vm-templates\studio-audio.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\vm-templates\gaming-launchers.md",
    "archiso-profile\airootfs\usr\share\lumina\windows-apps\vm-templates\restricted-gaming.md",
    "archiso-profile\airootfs\etc\systemd\system\ahmados-update-markers.service",
    "archiso-profile\airootfs\etc\systemd\system\ahmados-vm-guest-services.service",
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-firstboot.desktop",
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-vm-display-prep.desktop",
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-windows-apps-prep.desktop",
    "archiso-profile\airootfs\home\live\Desktop\Install Lumina-OS.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-export-diagnostics.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-firstboot-report.desktop",
    "archiso-profile\airootfs\usr\share\applications\ahmados-run-smoke-checks.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-finalize-install.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-installer.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-apps.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-launch-broker.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-compat-check.desktop",
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-vm-lab.desktop",
    "scripts\build-iso-arch.sh",
    "scripts\build-iso.ps1",
    "scripts\bootstrap-arch-build-env.sh",
    "scripts\validate-profile.sh",
    "scripts\write-build-manifest.sh",
    "scripts\export-build-handoff.sh",
    "scripts\new-vm-test-report.ps1",
    "scripts\new-install-test-report.ps1",
    "scripts\new-test-session.ps1",
    "scripts\start-vm-test-cycle.ps1",
    "scripts\finish-vm-test-cycle.ps1",
    "scripts\import-build-manifest.ps1",
    "scripts\import-build-handoff.ps1",
    "scripts\import-github-actions-artifact.ps1",
    "scripts\download-github-actions-artifact.ps1",
    "scripts\start-github-actions-install-test.ps1",
    "scripts\capture-virtualbox-guest-screenshot.ps1",
    "scripts\repair-virtualbox-display.ps1",
    "scripts\import-iso-artifact.ps1",
    "scripts\start-github-actions-vm-cycle.ps1",
    "scripts\finish-github-actions-vm-cycle.ps1",
    "scripts\new-cycle-handoff.ps1",
    "scripts\smoke-workflow-tools.ps1",
    "scripts\audit-cycle-chain.ps1",
    "scripts\audit-test-session.ps1",
    "scripts\sync-test-blockers.ps1",
    "scripts\sync-readiness-status.ps1",
    "scripts\sync-validation-matrix.ps1",
    "scripts\import-diagnostics-bundle.ps1",
    "scripts\prepare-release-package.ps1",
    "scripts\prepare-release-candidate.ps1",
    "scripts\sync-release-candidate-status.ps1",
    "scripts\validate-github-release-context.ps1",
    "scripts\sync-shareable-update.ps1",
    "scripts\sync-shareable-briefs.ps1",
    "scripts\validate-release-package.ps1",
    "scripts\publish-github-release.ps1",
    "status\builds\README.md",
    "status\build-handoffs\README.md",
    "status\build-imports\README.md",
    "status\iso-imports\README.md",
    "status\cycle-handoffs\README.md",
    "status\cycle-chain-audits\README.md",
    "status\vm-tests\README.md",
    "status\install-tests\README.md",
    "status\test-sessions\README.md",
    "status\test-session-audits\README.md",
    "status\diagnostics\README.md",
    "status\release-candidates\README.md",
    "status\release-candidates\CURRENT-RELEASE-CANDIDATE.md",
    "status\shareable-updates\README.md",
    "status\SHAREABLE-BRIEF.md",
    "status\SHAREABLE-BRIEF-AR.md",
    "status\releases\README.md",
    "status\blockers\README.md",
    "status\blockers\CURRENT-BLOCKERS.md",
    "status\readiness\README.md",
    "status\readiness\CURRENT-READINESS.md",
    "status\validation-matrix\README.md",
    "status\validation-matrix\CURRENT-VALIDATION-MATRIX.md",
    ".github\workflows\build-iso.yml",
    ".github\workflows\validate-profile.yml"
)

foreach ($relativePath in $requiredPaths) {
    Assert-PathExists $relativePath
}

$jsonFiles = @(
    "archiso-profile\airootfs\usr\share\ahmados\update-center\releases.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.classic\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\look-and-feel\com.ahmados.desktop.minimal\manifest.json",
    "archiso-profile\airootfs\usr\share\plasma\desktoptheme\LuminaGlass\metadata.json"
)

foreach ($jsonFile in $jsonFiles) {
    Test-JsonFile $jsonFile
}

$packageFile = Join-Path $RepoRoot "archiso-profile\packages.x86_64"
if (Test-Path $packageFile) {
    $packages = Get-Content $packageFile |
        Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") } |
        ForEach-Object { $_.Trim() }

    foreach ($requiredPackage in @("archinstall", "curl", "qt6-declarative", "qt6-svg", "systemsettings", "plasma-x11-session", "spectacle", "qemu-full", "libvirt", "virt-manager", "edk2-ovmf", "dnsmasq", "swtpm", "iptables-nft")) {
        if ($packages -notcontains $requiredPackage) {
            Add-Error "Missing expected package in packages.x86_64: $requiredPackage"
        }
    }
}

$mirrorlistPath = Join-Path $RepoRoot "archiso-profile\airootfs\etc\pacman.d\mirrorlist"
if (Test-Path $mirrorlistPath) {
    $activeServers = Get-Content $mirrorlistPath |
        Where-Object { $_ -match '^\s*Server\s*=' }

    if ($activeServers.Count -lt 1) {
        Add-Error "The live pacman mirrorlist does not contain any active Server entries."
    }
}

$wallpaperPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\share\ahmados\wallpapers"
if (Test-Path $wallpaperPath) {
    $wallpapers = Get-ChildItem $wallpaperPath -Filter *.svg -ErrorAction SilentlyContinue
    if ($wallpapers.Count -lt 3) {
        Add-Error "Expected at least three Lumina-OS wallpapers, found $($wallpapers.Count)."
    }
}

$plasmaThemeConfigPath = Join-Path $RepoRoot "archiso-profile\airootfs\home\live\.config\plasmarc"
if (Test-Path $plasmaThemeConfigPath) {
    $plasmaThemeConfig = Get-Content -Raw $plasmaThemeConfigPath
    if ($plasmaThemeConfig -notmatch 'name=default') {
        Add-Error "home/live/.config/plasmarc does not point to the default Plasma desktop theme."
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

$sessionDefaultsPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-apply-session-defaults"
if (Test-Path $sessionDefaultsPath) {
    $sessionDefaultsContent = Get-Content -Raw $sessionDefaultsPath
    if ($sessionDefaultsContent -notmatch 'desktop_theme_name="default"') {
        Add-Error "ahmados-apply-session-defaults does not set the default Plasma desktop theme."
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

$expectedExecMappings = @{
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-firstboot.desktop" = "Exec=/usr/local/bin/lumina-firstboot"
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-vm-display-prep.desktop" = "Exec=/usr/local/bin/lumina-vm-display-prep"
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-windows-apps-prep.desktop" = "Exec=/usr/local/bin/lumina-windows-apps-prep"
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-session-defaults.desktop" = "Exec=/usr/local/bin/lumina-apply-session-defaults"
    "archiso-profile\airootfs\home\live\.config\autostart\ahmados-welcome.desktop" = "Exec=/usr/local/bin/lumina-welcome --once"
    "archiso-profile\airootfs\usr\share\applications\ahmados-export-diagnostics.desktop" = "Exec=/usr/local/bin/lumina-export-diagnostics"
    "archiso-profile\airootfs\usr\share\applications\ahmados-firstboot-report.desktop" = "Exec=/usr/local/bin/lumina-open-firstboot-report"
    "archiso-profile\airootfs\usr\share\applications\ahmados-run-smoke-checks.desktop" = "Exec=/usr/local/bin/lumina-run-smoke-checks --open"
    "archiso-profile\airootfs\usr\share\applications\ahmados-update-center.desktop" = "Exec=/usr/local/bin/lumina-update-center"
    "archiso-profile\airootfs\usr\share\applications\ahmados-welcome.desktop" = "Exec=/usr/local/bin/lumina-welcome"
    "archiso-profile\airootfs\usr\share\applications\lumina-finalize-install.desktop" = "Exec=/usr/local/bin/lumina-finalize-install"
    "archiso-profile\airootfs\usr\share\applications\lumina-installer.desktop" = "Exec=/usr/local/bin/lumina-installer"
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-apps.desktop" = "Exec=/usr/local/bin/lumina-windows-workflow-hub"
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-launch-broker.desktop" = "Exec=/usr/local/bin/lumina-windows-launch-session --file %f"
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-compat-check.desktop" = "Exec=/usr/local/bin/lumina-windows-compat-check"
    "archiso-profile\airootfs\usr\share\applications\lumina-windows-vm-lab.desktop" = "Exec=/usr/local/bin/lumina-windows-vm-lab"
    "archiso-profile\airootfs\home\live\Desktop\Install Lumina-OS.desktop" = "Exec=/usr/local/bin/lumina-installer"
}

$customizeAirootfsPath = Join-Path $RepoRoot "archiso-profile\airootfs\root\customize_airootfs.sh"
if (Test-Path $customizeAirootfsPath) {
    $customizeContent = Get-Content -Raw $customizeAirootfsPath
    foreach ($requiredChmodTarget in @(
        "/usr/local/bin/ahmados-finalize-install",
        "/usr/local/bin/lumina-finalize-install",
        "/usr/local/bin/ahmados-apply-session-defaults",
        "/usr/local/bin/lumina-apply-session-defaults",
        "/usr/local/bin/ahmados-vm-display-prep",
        "/usr/local/bin/lumina-vm-display-prep",
        "/usr/local/bin/ahmados-vm-guest-services",
        "/usr/local/bin/lumina-vm-guest-services",
        "/usr/local/bin/ahmados-refresh-update-markers",
        "/usr/local/bin/lumina-refresh-update-markers",
        "/usr/local/bin/ahmados-capture-screenshot",
        "/usr/local/bin/lumina-capture-screenshot",
        "/usr/local/bin/ahmados-windows-apps-catalog",
        "/usr/local/bin/lumina-windows-apps-catalog",
        "/usr/local/bin/ahmados-windows-app-assistant",
        "/usr/local/bin/lumina-windows-app-assistant",
        "/usr/local/bin/ahmados-windows-profile-assistant",
        "/usr/local/bin/lumina-windows-profile-assistant",
        "/usr/local/bin/ahmados-windows-profile-runbook",
        "/usr/local/bin/lumina-windows-profile-runbook",
        "/usr/local/bin/ahmados-windows-workflow-bootstrap",
        "/usr/local/bin/lumina-windows-workflow-bootstrap",
        "/usr/local/bin/ahmados-windows-workflow-state",
        "/usr/local/bin/lumina-windows-workflow-state",
        "/usr/local/bin/ahmados-windows-workflow-mark",
        "/usr/local/bin/lumina-windows-workflow-mark",
        "/usr/local/bin/ahmados-windows-workflow-recipe",
        "/usr/local/bin/lumina-windows-workflow-recipe",
        "/usr/local/bin/ahmados-windows-workflow-hub",
        "/usr/local/bin/lumina-windows-workflow-hub",
        "/usr/local/bin/ahmados-windows-workflow-action-pack",
        "/usr/local/bin/lumina-windows-workflow-action-pack",
        "/usr/local/bin/ahmados-windows-workflow-next-action",
        "/usr/local/bin/lumina-windows-workflow-next-action",
        "/usr/local/bin/ahmados-windows-vm-template",
        "/usr/local/bin/lumina-windows-vm-template",
        "/usr/local/bin/ahmados-windows-vm-creation-starter",
        "/usr/local/bin/lumina-windows-vm-creation-starter",
        "/usr/local/bin/ahmados-windows-vm-postcreate",
        "/usr/local/bin/lumina-windows-vm-postcreate",
        "/usr/local/bin/ahmados-windows-app-install-starter",
        "/usr/local/bin/lumina-windows-app-install-starter",
        "/usr/local/bin/ahmados-windows-workflow-proof-pass",
        "/usr/local/bin/lumina-windows-workflow-proof-pass",
        "/usr/local/bin/ahmados-windows-launch-broker",
        "/usr/local/bin/lumina-windows-launch-broker",
        "/usr/local/bin/ahmados-windows-guest-agent-pack",
        "/usr/local/bin/lumina-windows-guest-agent-pack",
        "/usr/local/bin/ahmados-windows-vm-warm-start",
        "/usr/local/bin/lumina-windows-vm-warm-start",
        "/usr/local/bin/ahmados-windows-launch-results-sync",
        "/usr/local/bin/lumina-windows-launch-results-sync",
        "/usr/local/bin/ahmados-windows-launch-session",
        "/usr/local/bin/lumina-windows-launch-session",
        "/usr/local/bin/ahmados-windows-guest-onboarding",
        "/usr/local/bin/lumina-windows-guest-onboarding",
        "/usr/local/bin/ahmados-windows-app-registration",
        "/usr/local/bin/lumina-windows-app-registration",
        "/usr/local/bin/ahmados-windows-registered-app-launch",
        "/usr/local/bin/lumina-windows-registered-app-launch",
        "/usr/local/bin/ahmados-windows-app-launcher-pack",
        "/usr/local/bin/lumina-windows-app-launcher-pack",
        "/usr/local/bin/ahmados-windows-app-surfaces",
        "/usr/local/bin/lumina-windows-app-surfaces",
        "/usr/local/bin/ahmados-windows-registered-app-picker",
        "/usr/local/bin/lumina-windows-registered-app-picker"
    )) {
        if ($customizeContent -notmatch [regex]::Escape("chmod 755 $requiredChmodTarget")) {
            Add-Error "customize_airootfs.sh does not enforce executable permissions for $requiredChmodTarget"
        }
    }

    if ($customizeContent -notmatch 'systemctl enable ahmados-vm-guest-services\.service') {
        Add-Error "customize_airootfs.sh does not enable ahmados-vm-guest-services.service."
    }

    if ($customizeContent -notmatch 'systemctl enable ahmados-update-markers\.service') {
        Add-Error "customize_airootfs.sh does not enable ahmados-update-markers.service."
    }

    if ($customizeContent -notmatch 'touch /etc/\.updated') {
        Add-Error "customize_airootfs.sh does not refresh /etc/.updated."
    }

    if ($customizeContent -notmatch 'touch /var/\.updated') {
        Add-Error "customize_airootfs.sh does not refresh /var/.updated."
    }
}

$finalizeInstallPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-finalize-install"
if (Test-Path $finalizeInstallPath) {
    $finalizeContent = Get-Content -Raw $finalizeInstallPath
    if ($finalizeContent -notmatch '/etc/systemd/system/ahmados-vm-guest-services\.service') {
        Add-Error "ahmados-finalize-install does not copy the VM guest selector systemd unit."
    }
    if ($finalizeContent -notmatch '/etc/systemd/system/ahmados-update-markers\.service') {
        Add-Error "ahmados-finalize-install does not copy the update marker systemd unit."
    }
    if ($finalizeContent -notmatch 'ahmados-vm-guest-services\.service') {
        Add-Error "ahmados-finalize-install does not enable the VM guest selector service."
    }
    if ($finalizeContent -notmatch 'ahmados-update-markers\.service') {
        Add-Error "ahmados-finalize-install does not enable the update marker service."
    }

    if ($finalizeContent -notmatch 'touch "\$\{target_root\}/etc/\.updated"') {
        Add-Error "ahmados-finalize-install does not refresh target /etc/.updated."
    }

    if ($finalizeContent -notmatch 'touch "\$\{target_root\}/var/\.updated"') {
        Add-Error "ahmados-finalize-install does not refresh target /var/.updated."
    }
    if ($finalizeContent -notmatch 'pending-update-marker-refresh') {
        Add-Error "ahmados-finalize-install does not queue the first-boot update marker refresh."
    }
}

$vmDisplayPrepPath = Join-Path $RepoRoot "archiso-profile\airootfs\usr\local\bin\ahmados-vm-display-prep"
if (Test-Path $vmDisplayPrepPath) {
    $vmDisplayPrepContent = Get-Content -Raw $vmDisplayPrepPath
    if ($vmDisplayPrepContent -notmatch '1366x768') {
        Add-Error "ahmados-vm-display-prep does not define the expected VirtualBox fallback mode."
    }
}

foreach ($desktopPath in $expectedExecMappings.Keys) {
    $fullPath = Join-Path $RepoRoot $desktopPath
    if (-not (Test-Path $fullPath)) {
        continue
    }

    $desktopContent = Get-Content -Raw $fullPath
    $expectedExec = $expectedExecMappings[$desktopPath]
    if ($desktopContent -notmatch [regex]::Escape($expectedExec)) {
        Add-Error "Launcher does not use the expected Lumina runtime alias: $desktopPath"
    }
}

$mimeAppsPath = Join-Path $RepoRoot "archiso-profile\airootfs\home\live\.config\mimeapps.list"
if (Test-Path $mimeAppsPath) {
    $mimeAppsContent = Get-Content -Raw $mimeAppsPath
    foreach ($mimeMapping in @(
        "application/vnd.microsoft.portable-executable=lumina-windows-launch-broker.desktop;",
        "application/x-ms-dos-executable=lumina-windows-launch-broker.desktop;",
        "application/x-msdownload=lumina-windows-launch-broker.desktop;",
        "application/x-msi=lumina-windows-launch-broker.desktop;"
    )) {
        if ($mimeAppsContent -notmatch [regex]::Escape($mimeMapping)) {
            Add-Error "mimeapps.list does not register the expected Windows launch broker mapping: $mimeMapping"
        }
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
