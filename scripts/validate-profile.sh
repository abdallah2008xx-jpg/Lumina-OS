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
    "${profile_path}/airootfs/etc/sddm.conf.d/theme.conf"
    "${profile_path}/airootfs/etc/ahmados-release.conf"
    "${profile_path}/airootfs/usr/share/sddm/themes/ahmados/Main.qml"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop/manifest.json"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.classic/manifest.json"
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.minimal/manifest.json"
    "${profile_path}/airootfs/usr/share/color-schemes/AhmadOS.colors"
    "${profile_path}/airootfs/usr/share/color-schemes/AhmadOSNight.colors"
    "${profile_path}/airootfs/usr/share/ahmados/welcome/Main.qml"
    "${profile_path}/airootfs/usr/share/ahmados/update-center/Main.qml"
    "${profile_path}/airootfs/usr/share/ahmados/update-center/releases.json"
    "${profile_path}/airootfs/usr/local/bin/ahmados-export-diagnostics"
    "${profile_path}/airootfs/usr/local/bin/ahmados-run-smoke-checks"
    "${profile_path}/airootfs/usr/local/bin/ahmados-firstboot"
    "${profile_path}/airootfs/usr/local/bin/ahmados-open-firstboot-report"
    "${profile_path}/airootfs/usr/local/bin/ahmados-refresh-release-metadata"
    "${profile_path}/airootfs/usr/local/bin/ahmados-update-center"
    "${profile_path}/airootfs/usr/local/bin/ahmados-welcome"
    "${profile_path}/airootfs/home/live/.local/bin/ahmados-apply-session-defaults"
    "${profile_path}/airootfs/home/live/.config/autostart/ahmados-firstboot.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-export-diagnostics.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-firstboot-report.desktop"
    "${profile_path}/airootfs/usr/share/applications/ahmados-run-smoke-checks.desktop"
    "${repo_root}/scripts/build-iso-arch.sh"
    "${repo_root}/scripts/build-iso.ps1"
    "${repo_root}/scripts/bootstrap-arch-build-env.sh"
    "${repo_root}/scripts/write-build-manifest.sh"
    "${repo_root}/scripts/new-vm-test-report.ps1"
    "${repo_root}/scripts/new-test-session.ps1"
    "${repo_root}/scripts/start-vm-test-cycle.ps1"
    "${repo_root}/scripts/finish-vm-test-cycle.ps1"
    "${repo_root}/scripts/new-cycle-handoff.ps1"
    "${repo_root}/scripts/smoke-workflow-tools.ps1"
    "${repo_root}/scripts/audit-cycle-chain.ps1"
    "${repo_root}/scripts/audit-test-session.ps1"
    "${repo_root}/scripts/sync-test-blockers.ps1"
    "${repo_root}/scripts/sync-readiness-status.ps1"
    "${repo_root}/scripts/sync-validation-matrix.ps1"
    "${repo_root}/scripts/import-diagnostics-bundle.ps1"
    "${repo_root}/scripts/prepare-release-package.ps1"
    "${repo_root}/scripts/validate-release-package.ps1"
    "${repo_root}/scripts/publish-github-release.ps1"
    "${repo_root}/status/builds/README.md"
    "${repo_root}/status/cycle-handoffs/README.md"
    "${repo_root}/status/cycle-chain-audits/README.md"
    "${repo_root}/status/vm-tests/README.md"
    "${repo_root}/status/test-sessions/README.md"
    "${repo_root}/status/test-session-audits/README.md"
    "${repo_root}/status/diagnostics/README.md"
    "${repo_root}/status/releases/README.md"
    "${repo_root}/status/blockers/README.md"
    "${repo_root}/status/blockers/CURRENT-BLOCKERS.md"
    "${repo_root}/status/readiness/README.md"
    "${repo_root}/status/readiness/CURRENT-READINESS.md"
    "${repo_root}/status/validation-matrix/README.md"
    "${repo_root}/status/validation-matrix/CURRENT-VALIDATION-MATRIX.md"
)

for required_path in "${required_paths[@]}"; do
    assert_path_exists "${required_path}"
done

if [[ -f "${profile_path}/packages.x86_64" ]]; then
    for required_package in curl qt6-declarative qt6-svg systemsettings plasma-x11-session; do
        if ! grep -qx "${required_package}" "${profile_path}/packages.x86_64"; then
            add_error "Missing expected package in packages.x86_64: ${required_package}"
        fi
    done
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
if [[ -f "${export_diagnostics}" && ! grep -qi "diagnostics" "${export_diagnostics}" ]]; then
    add_warning "ahmados-export-diagnostics may not be writing a diagnostics bundle."
fi

if [[ -f "${export_diagnostics}" && ! grep -qi "smoke-check-report" "${export_diagnostics}" ]]; then
    add_warning "ahmados-export-diagnostics does not appear to include the smoke-check report."
fi

smoke_checks="${profile_path}/airootfs/usr/local/bin/ahmados-run-smoke-checks"
if [[ -f "${smoke_checks}" && ! grep -qi "Smoke Check Report" "${smoke_checks}" ]]; then
    add_warning "ahmados-run-smoke-checks may not be writing the expected report."
fi

for json_candidate in \
    "${profile_path}/airootfs/usr/share/ahmados/update-center/releases.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop/manifest.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.classic/manifest.json" \
    "${profile_path}/airootfs/usr/share/plasma/look-and-feel/com.ahmados.desktop.minimal/manifest.json"; do
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -m json.tool "${json_candidate}" >/dev/null 2>&1; then
            add_error "Invalid JSON in: ${json_candidate#${repo_root}/}"
        fi
    elif command -v python >/dev/null 2>&1; then
        if ! python -m json.tool "${json_candidate}" >/dev/null 2>&1; then
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
