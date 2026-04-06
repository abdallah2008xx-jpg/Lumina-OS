#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Lumina-OS profile validator

Usage:
  ./scripts/validate-profile.sh [--repo-root PATH] [--profile PATH]
EOF
}

repo_root=""
profile_path=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            repo_root="${2:-}"
            shift 2
            ;;
        --profile)
            profile_path="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${repo_root:-$(cd "${script_dir}/.." && pwd)}"
profile_path="${profile_path:-${repo_root}/archiso-profile}"

errors=()
warnings=()

add_error() {
    errors+=("$1")
}

add_warning() {
    warnings+=("$1")
}

assert_path_exists() {
    local path="$1"

    if [[ ! -e "${path}" ]]; then
        add_error "Missing required path: ${path#${repo_root}/}"
    fi
}

required_paths=(
    "${profile_path}/profiledef.sh"
    "${profile_path}/packages.x86_64"
    "${profile_path}/build-variants/sddm/stable-autologin.conf"
    "${profile_path}/build-variants/sddm/manual-login.conf"
    "${profile_path}/airootfs/etc/pacman.d/mirrorlist"
    "${profile_path}/airootfs/etc/sddm.conf.d/theme.conf"
    "${profile_path}/airootfs/etc/ahmados-release.conf"
    "${profile_path}/airootfs/usr/share/sddm/themes/ahmados/Main.qml"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop/manifest.json"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.classic/manifest.json"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.minimal/manifest.json"
    "${profile_path}/airootfs/usr/share/plasma/desktoptheme/LuminaGlass/metadata.json"
    "${profile_path}/airootfs/usr/share/plasma/desktoptheme/LuminaGlass/plasmarc"
    "${profile_path}/airootfs/usr/share/plasma/desktoptheme/LuminaGlass/widgets/panel-background.svg"
    "${profile_path}/airootfs/usr/share/plasma/desktoptheme/LuminaGlass/widgets/tasks.svg"
    "${profile_path}/airootfs/usr/share/color-schemes/AhmadOS.colors"
    "${profile_path}/airootfs/usr/share/color-schemes/AhmadOSNight.colors"
    "${profile_path}/airootfs/usr/share/ahmados/welcome/Main.qml"
    "${profile_path}/airootfs/usr/share/ahmados/update-center/Main.qml"
    "${profile_path}/airootfs/usr/share/ahmados/update-center/releases.json"
    "${profile_path}/airootfs/usr/local/bin/ahmados-export-diagnostics"
    "${profile_path}/airootfs/usr/local/bin/ahmados-apply-session-defaults"
    "${profile_path}/airootfs/usr/local/bin/ahmados-vm-display-prep"
    "${profile_path}/airootfs/usr/local/bin/ahmados-vm-guest-services"
    "${profile_path}/airootfs/usr/local/bin/ahmados-refresh-update-markers"
    "${profile_path}/airootfs/usr/local/bin/ahmados-finalize-install"
    "${profile_path}/airootfs/usr/local/bin/ahmados-installer"
    "${profile_path}/airootfs/usr/local/bin/ahmados-run-smoke-checks"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-compat-check"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-vm-lab"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-surface"
    "${profile_path}/airootfs/usr/local/bin/ahmados-firstboot"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-apps"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-assistant"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-profile-assistant"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-profile-runbook"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-bootstrap"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-state"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-mark"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-recipe"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-hub"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-action-pack"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-next-action"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-vm-template"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-vm-creation-starter"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-vm-postcreate"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-install-starter"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-workflow-proof-pass"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-launch-broker"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-guest-agent-pack"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-vm-warm-start"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-launch-results-sync"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-launch-session"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-guest-onboarding"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-registration"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-registered-app-launch"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-launcher-pack"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-surfaces"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-registered-app-picker"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-guest-app-discovery"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-manifest-hydration"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-menu-export"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-installed-app-sync"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-guest-app-publish-pack"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-publish-sync"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-collections"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-collection-launch"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-collection-menu-export"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-app-library"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-apps-catalog"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-apps-prep"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-menu-export"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-app-pack"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-app-picker"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-recent-sync"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-quick-launch"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-runtime"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-refresh"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-home"
    "${profile_path}/airootfs/usr/local/bin/ahmados-windows-daily-home-refresh"
    "${profile_path}/airootfs/usr/local/bin/ahmados-open-install-finalize-report"
    "${profile_path}/airootfs/usr/local/bin/ahmados-hardware-readiness-check"
    "${profile_path}/airootfs/usr/local/bin/ahmados-capture-screenshot"
    "${profile_path}/airootfs/usr/local/bin/ahmados-open-firstboot-report"
    "${profile_path}/airootfs/usr/local/bin/ahmados-refresh-release-metadata"
    "${profile_path}/airootfs/usr/local/bin/ahmados-update-center"
    "${profile_path}/airootfs/usr/local/bin/ahmados-welcome"
    "${profile_path}/airootfs/usr/local/bin/lumina-capture-screenshot"
    "${profile_path}/airootfs/usr/local/bin/lumina-apply-session-defaults"
    "${profile_path}/airootfs/usr/local/bin/lumina-vm-display-prep"
    "${profile_path}/airootfs/usr/local/bin/lumina-vm-guest-services"
    "${profile_path}/airootfs/usr/local/bin/lumina-refresh-update-markers"
    "${profile_path}/airootfs/usr/local/bin/lumina-export-diagnostics"
    "${profile_path}/airootfs/usr/local/bin/lumina-finalize-install"
    "${profile_path}/airootfs/usr/local/bin/lumina-installer"
    "${profile_path}/airootfs/usr/local/bin/lumina-run-smoke-checks"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-compat-check"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-vm-lab"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-surface"
    "${profile_path}/airootfs/usr/local/bin/lumina-firstboot"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-apps"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-assistant"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-profile-assistant"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-profile-runbook"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-bootstrap"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-state"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-mark"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-recipe"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-hub"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-action-pack"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-next-action"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-vm-template"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-vm-creation-starter"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-vm-postcreate"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-install-starter"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-workflow-proof-pass"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-launch-broker"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-guest-agent-pack"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-vm-warm-start"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-launch-results-sync"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-launch-session"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-guest-onboarding"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-registration"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-registered-app-launch"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-launcher-pack"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-surfaces"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-registered-app-picker"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-guest-app-discovery"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-manifest-hydration"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-menu-export"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-installed-app-sync"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-guest-app-publish-pack"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-publish-sync"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-collections"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-collection-launch"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-collection-menu-export"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-app-library"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-apps-catalog"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-apps-prep"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-menu-export"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-app-pack"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-app-picker"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-recent-sync"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-quick-launch"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-runtime"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-refresh"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-home"
    "${profile_path}/airootfs/usr/local/bin/lumina-windows-daily-home-refresh"
    "${profile_path}/airootfs/usr/local/bin/lumina-open-install-finalize-report"
    "${profile_path}/airootfs/usr/local/bin/lumina-hardware-readiness-check"
    "${profile_path}/airootfs/usr/local/bin/lumina-open-firstboot-report"
    "${profile_path}/airootfs/usr/local/bin/lumina-refresh-release-metadata"
    "${profile_path}/airootfs/usr/local/bin/lumina-update-center"
    "${profile_path}/airootfs/usr/local/bin/lumina-welcome"
    "${profile_path}/airootfs/home/live/.local/bin/ahmados-apply-session-defaults"
    "${profile_path}/airootfs/home/live/.local/bin/lumina-apply-session-defaults"
    "${profile_path}/airootfs/home/live/.config/plasmarc"
    "${profile_path}/airootfs/home/live/.config/mimeapps.list"
    "${profile_path}/airootfs/usr/local/lib/ahmados-session-context.sh"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/catalog.tsv"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/profiles.tsv"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/manifests/adobe-creator.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/manifests/office-productivity.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/manifests/studio-audio.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/manifests/gaming-launchers.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/manifests/restricted-gaming.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/recipes/adobe-creator.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/recipes/office-productivity.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/recipes/studio-audio.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/recipes/gaming-launchers.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/recipes/restricted-gaming.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/vm-templates/adobe-creator.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/vm-templates/office-productivity.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/vm-templates/studio-audio.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/vm-templates/gaming-launchers.md"
    "${profile_path}/airootfs/usr/share/lumina/windows-apps/vm-templates/restricted-gaming.md"
    "${profile_path}/airootfs/etc/systemd/system/ahmados-update-markers.service"
    "${profile_path}/airootfs/etc/systemd/system/ahmados-vm-guest-services.service"
    "${profile_path}/airootfs/home/live/.config/autostart/ahmados-firstboot.desktop"
    "${profile_path}/airootfs/home/live/.config/autostart/ahmados-vm-display-prep.desktop"
    "${profile_path}/airootfs/home/live/.config/autostart/ahmados-windows-apps-prep.desktop"
    "${profile_path}/airootfs/home/live/Desktop/Install Lumina-OS.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-export-diagnostics.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-firstboot-report.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-run-smoke-checks.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-finalize-install.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-hardware-readiness-check.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-install-finalize-report.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-installer.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-windows-apps.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-windows-workflow-chooser.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-windows-launch-broker.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-windows-compat-check.desktop"
    "${profile_path}/airootfs/usr/share/applications/lumina-windows-vm-lab.desktop"
    "${repo_root}/scripts/build-iso-arch.sh"
    "${repo_root}/scripts/build-iso.ps1"
    "${repo_root}/scripts/bootstrap-arch-build-env.sh"
    "${repo_root}/scripts/write-build-manifest.sh"
    "${repo_root}/scripts/export-build-handoff.sh"
    "${repo_root}/scripts/new-vm-test-report.ps1"
    "${repo_root}/scripts/new-login-test-report.ps1"
    "${repo_root}/scripts/new-install-test-report.ps1"
    "${repo_root}/scripts/new-hardware-test-report.ps1"
    "${repo_root}/scripts/new-test-session.ps1"
    "${repo_root}/scripts/start-vm-test-cycle.ps1"
    "${repo_root}/scripts/finish-vm-test-cycle.ps1"
    "${repo_root}/scripts/import-build-manifest.ps1"
    "${repo_root}/scripts/import-build-handoff.ps1"
    "${repo_root}/scripts/import-github-actions-artifact.ps1"
    "${repo_root}/scripts/download-github-actions-artifact.ps1"
    "${repo_root}/scripts/start-github-actions-install-test.ps1"
    "${repo_root}/scripts/capture-virtualbox-guest-screenshot.ps1"
    "${repo_root}/scripts/repair-virtualbox-display.ps1"
    "${repo_root}/scripts/import-iso-artifact.ps1"
    "${repo_root}/scripts/start-github-actions-vm-cycle.ps1"
    "${repo_root}/scripts/finish-github-actions-vm-cycle.ps1"
    "${repo_root}/scripts/new-cycle-handoff.ps1"
    "${repo_root}/scripts/smoke-workflow-tools.ps1"
    "${repo_root}/scripts/audit-cycle-chain.ps1"
    "${repo_root}/scripts/audit-test-session.ps1"
    "${repo_root}/scripts/sync-test-blockers.ps1"
    "${repo_root}/scripts/sync-readiness-status.ps1"
    "${repo_root}/scripts/sync-validation-matrix.ps1"
    "${repo_root}/scripts/import-diagnostics-bundle.ps1"
    "${repo_root}/scripts/prepare-release-package.ps1"
    "${repo_root}/scripts/audit-release-evidence.ps1"
    "${repo_root}/scripts/audit-release-readiness.ps1"
    "${repo_root}/scripts/prepare-release-candidate.ps1"
    "${repo_root}/scripts/sync-release-candidate-status.ps1"
    "${repo_root}/scripts/validate-github-release-context.ps1"
    "${repo_root}/scripts/sync-shareable-update.ps1"
    "${repo_root}/scripts/sync-shareable-briefs.ps1"
    "${repo_root}/scripts/validate-release-package.ps1"
    "${repo_root}/scripts/publish-github-release.ps1"
    "${repo_root}/status/builds/README.md"
    "${repo_root}/status/build-handoffs/README.md"
    "${repo_root}/status/build-imports/README.md"
    "${repo_root}/status/iso-imports/README.md"
    "${repo_root}/status/cycle-handoffs/README.md"
    "${repo_root}/status/cycle-chain-audits/README.md"
    "${repo_root}/status/vm-tests/README.md"
    "${repo_root}/status/login-tests/README.md"
    "${repo_root}/status/install-tests/README.md"
    "${repo_root}/status/hardware-tests/README.md"
    "${repo_root}/status/test-sessions/README.md"
    "${repo_root}/status/test-session-audits/README.md"
    "${repo_root}/status/diagnostics/README.md"
    "${repo_root}/status/release-candidates/README.md"
    "${repo_root}/status/release-candidates/CURRENT-RELEASE-CANDIDATE.md"
    "${repo_root}/status/shareable-updates/README.md"
    "${repo_root}/status/SHAREABLE-BRIEF.md"
    "${repo_root}/status/SHAREABLE-BRIEF-AR.md"
    "${repo_root}/status/releases/README.md"
    "${repo_root}/status/blockers/README.md"
    "${repo_root}/status/blockers/CURRENT-BLOCKERS.md"
    "${repo_root}/status/readiness/README.md"
    "${repo_root}/status/readiness/CURRENT-READINESS.md"
    "${repo_root}/status/validation-matrix/README.md"
    "${repo_root}/status/validation-matrix/CURRENT-VALIDATION-MATRIX.md"
    "${repo_root}/.github/workflows/build-iso.yml"
    "${repo_root}/.github/workflows/validate-profile.yml"
)

for required_path in "${required_paths[@]}"; do
    assert_path_exists "${required_path}"
done

if [[ -f "${profile_path}/packages.x86_64" ]]; then
    for required_package in archinstall curl qt6-declarative qt6-svg systemsettings plasma-x11-session spectacle qemu-full libvirt virt-manager edk2-ovmf dnsmasq swtpm iptables-nft; do
        if ! grep -qx "${required_package}" "${profile_path}/packages.x86_64"; then
            add_error "Missing expected package in packages.x86_64: ${required_package}"
        fi
    done
fi

mirrorlist_path="${profile_path}/airootfs/etc/pacman.d/mirrorlist"
if [[ -f "${mirrorlist_path}" ]]; then
    if ! grep -Eq '^[[:space:]]*Server[[:space:]]*=' "${mirrorlist_path}"; then
        add_error "The live pacman mirrorlist does not contain any active Server entries."
    fi
fi

wallpaper_dir="${profile_path}/airootfs/usr/share/ahmados/wallpapers"
if [[ -d "${wallpaper_dir}" ]]; then
    shopt -s nullglob
    wallpapers=("${wallpaper_dir}"/*.svg)
    shopt -u nullglob

    if [[ ${#wallpapers[@]} -lt 3 ]]; then
        add_error "Expected at least three Lumina-OS wallpapers, found ${#wallpapers[@]}."
    fi
else
    add_error "Missing wallpaper directory: ${wallpaper_dir#${repo_root}/}"
fi

plasma_theme_config="${profile_path}/airootfs/home/live/.config/plasmarc"
if [[ -f "${plasma_theme_config}" ]] && ! grep -q 'name=default' "${plasma_theme_config}"; then
    add_error "home/live/.config/plasmarc does not point to the default Plasma desktop theme."
fi

theme_conf="${profile_path}/airootfs/etc/sddm.conf.d/theme.conf"
if [[ -f "${theme_conf}" ]]; then
    current_theme="$(awk -F= '/^Current=/{print $2; exit}' "${theme_conf}")"

    if [[ -z "${current_theme}" ]]; then
        add_error "Could not find Current=... in theme.conf"
    elif [[ ! -f "${profile_path}/airootfs/usr/share/sddm/themes/${current_theme}/Main.qml" ]]; then
        add_error "SDDM theme points to missing Main.qml: ${current_theme}"
    fi
fi

profiledef="${profile_path}/profiledef.sh"
if [[ -f "${profiledef}" ]]; then
    while IFS= read -r permission_target; do
        case "${permission_target}" in
            /etc/shadow)
                continue
                ;;
        esac

        relative_target="${permission_target#/}"
        if [[ ! -e "${profile_path}/airootfs/${relative_target}" ]]; then
            add_error "profiledef.sh references a missing permission target: ${permission_target}"
        fi
    done < <(grep -oE '\["/[^"]+"\]' "${profiledef}" | sed 's/^\["//; s/"\]$//')
fi

release_config="${profile_path}/airootfs/etc/ahmados-release.conf"
if [[ -f "${release_config}" ]]; then
    for required_variable in AHMADOS_RELEASES_SOURCE AHMADOS_GITHUB_OWNER AHMADOS_GITHUB_REPO AHMADOS_INSTALLED_VERSION; do
        if ! grep -q "${required_variable}" "${release_config}"; then
            add_error "Missing expected release variable in etc/ahmados-release.conf: ${required_variable}"
        fi
    done
fi

session_defaults="${profile_path}/airootfs/usr/local/bin/ahmados-apply-session-defaults"
if [[ -f "${session_defaults}" ]] && ! grep -q 'desktop_theme_name="default"' "${session_defaults}"; then
    add_error "ahmados-apply-session-defaults does not set the default Plasma desktop theme."
fi

firstboot="${profile_path}/airootfs/usr/local/bin/ahmados-firstboot"
if [[ -f "${firstboot}" ]]; then
    if grep -qi "placeholder" "${firstboot}"; then
        add_error "ahmados-firstboot is still a placeholder."
    fi

    if ! grep -q "firstboot-report" "${firstboot}"; then
        add_warning "ahmados-firstboot does not appear to write a firstboot report."
    fi
fi

export_diagnostics="${profile_path}/airootfs/usr/local/bin/ahmados-export-diagnostics"
if [[ -f "${export_diagnostics}" ]] && ! grep -qi "diagnostics" "${export_diagnostics}"; then
    add_warning "ahmados-export-diagnostics may not be writing a diagnostics bundle."
fi

if [[ -f "${export_diagnostics}" ]] && ! grep -qi "smoke-check-report" "${export_diagnostics}"; then
    add_warning "ahmados-export-diagnostics does not appear to include the smoke-check report."
fi

smoke_checks="${profile_path}/airootfs/usr/local/bin/ahmados-run-smoke-checks"
if [[ -f "${smoke_checks}" ]] && ! grep -qi "Smoke Check Report" "${smoke_checks}"; then
    add_warning "ahmados-run-smoke-checks may not be writing the expected report."
fi

customize_airootfs="${profile_path}/airootfs/root/customize_airootfs.sh"
if [[ -f "${customize_airootfs}" ]]; then
    for required_chmod_target in \
        /usr/local/bin/ahmados-finalize-install \
        /usr/local/bin/lumina-finalize-install \
        /usr/local/bin/ahmados-apply-session-defaults \
        /usr/local/bin/lumina-apply-session-defaults \
        /usr/local/bin/ahmados-vm-display-prep \
        /usr/local/bin/lumina-vm-display-prep \
        /usr/local/bin/ahmados-vm-guest-services \
        /usr/local/bin/lumina-vm-guest-services \
        /usr/local/bin/ahmados-refresh-update-markers \
        /usr/local/bin/lumina-refresh-update-markers \
        /usr/local/bin/ahmados-capture-screenshot \
        /usr/local/bin/lumina-capture-screenshot \
        /usr/local/bin/ahmados-windows-apps-catalog \
        /usr/local/bin/lumina-windows-apps-catalog \
        /usr/local/bin/ahmados-windows-app-assistant \
        /usr/local/bin/lumina-windows-app-assistant \
        /usr/local/bin/ahmados-windows-profile-assistant \
        /usr/local/bin/lumina-windows-profile-assistant \
        /usr/local/bin/ahmados-windows-profile-runbook \
        /usr/local/bin/lumina-windows-profile-runbook \
        /usr/local/bin/ahmados-windows-workflow-bootstrap \
        /usr/local/bin/lumina-windows-workflow-bootstrap \
        /usr/local/bin/ahmados-windows-workflow-state \
        /usr/local/bin/lumina-windows-workflow-state \
        /usr/local/bin/ahmados-windows-workflow-mark \
        /usr/local/bin/lumina-windows-workflow-mark \
        /usr/local/bin/ahmados-windows-workflow-recipe \
        /usr/local/bin/lumina-windows-workflow-recipe \
        /usr/local/bin/ahmados-windows-workflow-hub \
        /usr/local/bin/lumina-windows-workflow-hub \
        /usr/local/bin/ahmados-windows-workflow-action-pack \
        /usr/local/bin/lumina-windows-workflow-action-pack \
        /usr/local/bin/ahmados-windows-workflow-next-action \
        /usr/local/bin/lumina-windows-workflow-next-action \
        /usr/local/bin/ahmados-windows-vm-template \
        /usr/local/bin/lumina-windows-vm-template \
        /usr/local/bin/ahmados-windows-vm-creation-starter \
        /usr/local/bin/lumina-windows-vm-creation-starter \
        /usr/local/bin/ahmados-windows-vm-postcreate \
        /usr/local/bin/lumina-windows-vm-postcreate \
        /usr/local/bin/ahmados-windows-app-install-starter \
        /usr/local/bin/lumina-windows-app-install-starter \
        /usr/local/bin/ahmados-windows-workflow-proof-pass \
        /usr/local/bin/lumina-windows-workflow-proof-pass \
        /usr/local/bin/ahmados-windows-launch-broker \
        /usr/local/bin/lumina-windows-launch-broker \
        /usr/local/bin/ahmados-windows-guest-agent-pack \
        /usr/local/bin/lumina-windows-guest-agent-pack \
        /usr/local/bin/ahmados-windows-vm-warm-start \
        /usr/local/bin/lumina-windows-vm-warm-start \
        /usr/local/bin/ahmados-windows-launch-results-sync \
        /usr/local/bin/lumina-windows-launch-results-sync \
        /usr/local/bin/ahmados-windows-launch-session \
        /usr/local/bin/lumina-windows-launch-session \
        /usr/local/bin/ahmados-windows-guest-onboarding \
        /usr/local/bin/lumina-windows-guest-onboarding \
        /usr/local/bin/ahmados-windows-app-registration \
        /usr/local/bin/lumina-windows-app-registration \
        /usr/local/bin/ahmados-windows-registered-app-launch \
        /usr/local/bin/lumina-windows-registered-app-launch \
        /usr/local/bin/ahmados-windows-app-launcher-pack \
        /usr/local/bin/lumina-windows-app-launcher-pack \
        /usr/local/bin/ahmados-windows-app-surfaces \
        /usr/local/bin/lumina-windows-app-surfaces \
        /usr/local/bin/ahmados-windows-registered-app-picker \
        /usr/local/bin/lumina-windows-registered-app-picker \
        /usr/local/bin/ahmados-windows-guest-app-discovery \
        /usr/local/bin/lumina-windows-guest-app-discovery \
        /usr/local/bin/ahmados-windows-app-manifest-hydration \
        /usr/local/bin/lumina-windows-app-manifest-hydration \
        /usr/local/bin/ahmados-windows-app-menu-export \
        /usr/local/bin/lumina-windows-app-menu-export \
        /usr/local/bin/ahmados-windows-installed-app-sync \
        /usr/local/bin/lumina-windows-installed-app-sync \
        /usr/local/bin/ahmados-windows-guest-app-publish-pack \
        /usr/local/bin/lumina-windows-guest-app-publish-pack \
        /usr/local/bin/ahmados-windows-app-publish-sync \
        /usr/local/bin/lumina-windows-app-publish-sync \
        /usr/local/bin/ahmados-windows-app-collections \
        /usr/local/bin/lumina-windows-app-collections \
        /usr/local/bin/ahmados-windows-collection-launch \
        /usr/local/bin/lumina-windows-collection-launch \
        /usr/local/bin/ahmados-windows-collection-menu-export \
        /usr/local/bin/lumina-windows-collection-menu-export \
        /usr/local/bin/ahmados-windows-app-library \
        /usr/local/bin/lumina-windows-app-library \
        /usr/local/bin/ahmados-windows-daily-surface \
        /usr/local/bin/lumina-windows-daily-surface \
        /usr/local/bin/ahmados-windows-daily-menu-export \
        /usr/local/bin/lumina-windows-daily-menu-export \
        /usr/local/bin/ahmados-windows-daily-app-pack \
        /usr/local/bin/lumina-windows-daily-app-pack \
        /usr/local/bin/ahmados-windows-daily-app-picker \
        /usr/local/bin/lumina-windows-daily-app-picker \
        /usr/local/bin/ahmados-windows-daily-recent-sync \
        /usr/local/bin/lumina-windows-daily-recent-sync \
        /usr/local/bin/ahmados-windows-daily-quick-launch \
        /usr/local/bin/lumina-windows-daily-quick-launch \
        /usr/local/bin/ahmados-windows-daily-runtime \
        /usr/local/bin/lumina-windows-daily-runtime \
        /usr/local/bin/ahmados-windows-daily-refresh \
        /usr/local/bin/lumina-windows-daily-refresh \
        /usr/local/bin/ahmados-windows-daily-home \
        /usr/local/bin/lumina-windows-daily-home \
        /usr/local/bin/ahmados-windows-daily-home-refresh \
        /usr/local/bin/lumina-windows-daily-home-refresh \
        /usr/local/bin/ahmados-open-install-finalize-report \
        /usr/local/bin/lumina-open-install-finalize-report \
        /usr/local/bin/ahmados-hardware-readiness-check \
        /usr/local/bin/lumina-hardware-readiness-check; do
        if ! grep -Fq "chmod 755 ${required_chmod_target}" "${customize_airootfs}"; then
            add_error "customize_airootfs.sh does not enforce executable permissions for ${required_chmod_target}"
        fi
    done

    if ! grep -Fq "systemctl enable ahmados-vm-guest-services.service" "${customize_airootfs}"; then
        add_error "customize_airootfs.sh does not enable ahmados-vm-guest-services.service."
    fi

    if ! grep -Fq "systemctl enable ahmados-update-markers.service" "${customize_airootfs}"; then
        add_error "customize_airootfs.sh does not enable ahmados-update-markers.service."
    fi

    if ! grep -Fq "touch /etc/.updated" "${customize_airootfs}"; then
        add_error "customize_airootfs.sh does not refresh /etc/.updated."
    fi

    if ! grep -Fq "touch /var/.updated" "${customize_airootfs}"; then
        add_error "customize_airootfs.sh does not refresh /var/.updated."
    fi
fi

finalize_install="${profile_path}/airootfs/usr/local/bin/ahmados-finalize-install"
if [[ -f "${finalize_install}" ]]; then
    if ! grep -Fq "/etc/systemd/system/ahmados-vm-guest-services.service" "${finalize_install}"; then
        add_error "ahmados-finalize-install does not copy the VM guest selector systemd unit."
    fi

    if ! grep -Fq "/etc/systemd/system/ahmados-update-markers.service" "${finalize_install}"; then
        add_error "ahmados-finalize-install does not copy the update marker systemd unit."
    fi

    if ! grep -Fq "ahmados-vm-guest-services.service" "${finalize_install}"; then
        add_error "ahmados-finalize-install does not enable the VM guest selector service."
    fi

    if ! grep -Fq "ahmados-update-markers.service" "${finalize_install}"; then
        add_error "ahmados-finalize-install does not enable the update marker service."
    fi

    if ! grep -Fq 'touch "${target_root}/etc/.updated"' "${finalize_install}"; then
        add_error "ahmados-finalize-install does not refresh target /etc/.updated."
    fi

    if ! grep -Fq 'touch "${target_root}/var/.updated"' "${finalize_install}"; then
        add_error "ahmados-finalize-install does not refresh target /var/.updated."
    fi

    if ! grep -Fq 'pending-update-marker-refresh' "${finalize_install}"; then
        add_error "ahmados-finalize-install does not queue the first-boot update marker refresh."
    fi
fi

vm_display_prep="${profile_path}/airootfs/usr/local/bin/ahmados-vm-display-prep"
if [[ -f "${vm_display_prep}" ]] && ! grep -Fq "1366x768" "${vm_display_prep}"; then
    add_error "ahmados-vm-display-prep does not define the expected VirtualBox fallback mode."
fi

while IFS='|' read -r desktop_path expected_exec; do
    [[ -n "${desktop_path}" ]] || continue

    if [[ -f "${desktop_path}" ]] && ! grep -Fq "${expected_exec}" "${desktop_path}"; then
        add_error "Launcher does not use the expected Lumina runtime alias: ${desktop_path#${repo_root}/}"
    fi
done <<EOF
${profile_path}/airootfs/home/live/.config/autostart/ahmados-firstboot.desktop|Exec=/usr/local/bin/lumina-firstboot
${profile_path}/airootfs/home/live/.config/autostart/ahmados-vm-display-prep.desktop|Exec=/usr/local/bin/lumina-vm-display-prep
${profile_path}/airootfs/home/live/.config/autostart/ahmados-windows-apps-prep.desktop|Exec=/usr/local/bin/lumina-windows-apps-prep
${profile_path}/airootfs/home/live/.config/autostart/ahmados-session-defaults.desktop|Exec=/usr/local/bin/lumina-apply-session-defaults
${profile_path}/airootfs/home/live/.config/autostart/ahmados-welcome.desktop|Exec=/usr/local/bin/lumina-welcome --once
${profile_path}/airootfs/usr/share/applications/ahmados-export-diagnostics.desktop|Exec=/usr/local/bin/lumina-export-diagnostics
${profile_path}/airootfs/usr/share/applications/ahmados-firstboot-report.desktop|Exec=/usr/local/bin/lumina-open-firstboot-report
${profile_path}/airootfs/usr/share/applications/ahmados-run-smoke-checks.desktop|Exec=/usr/local/bin/lumina-run-smoke-checks --open
${profile_path}/airootfs/usr/share/applications/ahmados-update-center.desktop|Exec=/usr/local/bin/lumina-update-center
${profile_path}/airootfs/usr/share/applications/ahmados-welcome.desktop|Exec=/usr/local/bin/lumina-welcome
${profile_path}/airootfs/usr/share/applications/lumina-finalize-install.desktop|Exec=/usr/local/bin/lumina-finalize-install
${profile_path}/airootfs/usr/share/applications/lumina-hardware-readiness-check.desktop|Exec=/usr/local/bin/lumina-hardware-readiness-check --open
${profile_path}/airootfs/usr/share/applications/lumina-install-finalize-report.desktop|Exec=/usr/local/bin/lumina-open-install-finalize-report
${profile_path}/airootfs/usr/share/applications/lumina-installer.desktop|Exec=/usr/local/bin/lumina-installer
${profile_path}/airootfs/usr/share/applications/lumina-windows-apps.desktop|Exec=/usr/local/bin/lumina-windows-daily-home --launch
${profile_path}/airootfs/usr/share/applications/lumina-windows-workflow-chooser.desktop|Exec=/usr/local/bin/lumina-windows-daily-home --choose-workflow --launch
${profile_path}/airootfs/usr/share/applications/lumina-windows-launch-broker.desktop|Exec=/usr/local/bin/lumina-windows-launch-session --file %f
${profile_path}/airootfs/usr/share/applications/lumina-windows-compat-check.desktop|Exec=/usr/local/bin/lumina-windows-compat-check
${profile_path}/airootfs/usr/share/applications/lumina-windows-vm-lab.desktop|Exec=/usr/local/bin/lumina-windows-vm-lab
${profile_path}/airootfs/home/live/Desktop/Install Lumina-OS.desktop|Exec=/usr/local/bin/lumina-installer
EOF

mimeapps_list="${profile_path}/airootfs/home/live/.config/mimeapps.list"
if [[ -f "${mimeapps_list}" ]]; then
    for expected_mime_mapping in \
        'application/vnd.microsoft.portable-executable=lumina-windows-launch-broker.desktop;' \
        'application/x-ms-dos-executable=lumina-windows-launch-broker.desktop;' \
        'application/x-msdownload=lumina-windows-launch-broker.desktop;' \
        'application/x-msi=lumina-windows-launch-broker.desktop;'; do
        if ! grep -Fq "${expected_mime_mapping}" "${mimeapps_list}"; then
            add_error "mimeapps.list does not register the expected Windows launch broker mapping: ${expected_mime_mapping}"
        fi
    done
fi

json_validator_bin=""
for python_candidate in python3 python; do
    if command -v "${python_candidate}" >/dev/null 2>&1 && "${python_candidate}" -c "import json" >/dev/null 2>&1; then
        json_validator_bin="${python_candidate}"
        break
    fi
done

for json_candidate in \
    "${profile_path}/airootfs/usr/share/ahmados/update-center/releases.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop/manifest.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.classic/manifest.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.minimal/manifest.json" \
    "${profile_path}/airootfs/usr/share/plasma/desktoptheme/LuminaGlass/metadata.json"; do
    if [[ -n "${json_validator_bin}" ]]; then
        if ! "${json_validator_bin}" -m json.tool "${json_candidate}" >/dev/null 2>&1; then
            add_error "Invalid JSON in: ${json_candidate#${repo_root}/}"
        fi
    else
        add_warning "Skipping JSON validation because python is unavailable in this environment."
        break
    fi
done

if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "Warnings:"
    for warning in "${warnings[@]}"; do
        echo " - ${warning}"
    done
    echo ""
fi

if [[ ${#errors[@]} -gt 0 ]]; then
    echo "Lumina-OS profile validation failed."
    for error_message in "${errors[@]}"; do
        echo " - ${error_message}"
    done
    exit 1
fi

echo "Lumina-OS profile validation passed."
