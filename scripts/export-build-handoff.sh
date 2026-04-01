#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Lumina-OS build handoff exporter

Usage:
  ./scripts/export-build-handoff.sh [--mode stable|login-test] [--run-label LABEL] [--manifest PATH] [--iso PATH] [--out-dir PATH]

Purpose:
  Collect the build manifest and ISO into one transferable folder after a real Arch-side build.
EOF
}

mode="stable"
run_label=""
manifest_path=""
iso_path=""
out_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            mode="${2:-}"
            shift 2
            ;;
        --run-label)
            run_label="${2:-}"
            shift 2
            ;;
        --manifest)
            manifest_path="${2:-}"
            shift 2
            ;;
        --iso)
            iso_path="${2:-}"
            shift 2
            ;;
        --out-dir)
            out_dir="${2:-}"
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

if [[ "${mode}" != "stable" && "${mode}" != "login-test" ]]; then
    echo "Unsupported mode: ${mode}" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
builds_root="${repo_root}/status/builds"
default_iso_dir="${repo_root}/build/out/${mode}"

get_metadata_value() {
    local file_path="$1"
    local label="$2"

    awk -v target="- ${label}: " 'index($0, target) == 1 { print substr($0, length(target) + 1); exit }' "${file_path}"
}

safe_segment() {
    local value="$1"
    value="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9.-]+/-/g; s/^-+//; s/-+$//')"
    if [[ -z "${value}" ]]; then
        value="unknown"
    fi
    printf '%s\n' "${value}"
}

find_manifest_by_run_label() {
    local search_root="$1"
    local target_run_label="$2"

    find "${search_root}" -type f -name '*.md' ! -name 'README.md' ! -name 'CURRENT-*.md' -print0 2>/dev/null |
        while IFS= read -r -d '' candidate; do
            if grep -Fq -- "- Run Label: ${target_run_label}" "${candidate}" 2>/dev/null; then
                printf '%s\n' "${candidate}"
            fi
        done | tail -n 1
}

find_latest_mode_manifest() {
    local search_root="$1"
    local target_mode="$2"

    find "${search_root}" -type f -name '*.md' ! -name 'README.md' ! -name 'CURRENT-*.md' -print0 2>/dev/null |
        while IFS= read -r -d '' candidate; do
            if grep -Fq -- "- Mode: ${target_mode}" "${candidate}" 2>/dev/null; then
                printf '%s\n' "${candidate}"
            fi
        done | tail -n 1
}

if [[ -z "${manifest_path}" ]]; then
    if [[ -n "${run_label}" ]]; then
        manifest_path="$(find_manifest_by_run_label "${builds_root}" "${run_label}")"
    fi

    if [[ -z "${manifest_path}" ]]; then
        manifest_path="$(find_latest_mode_manifest "${builds_root}" "${mode}")"
    fi
fi

if [[ -z "${manifest_path}" || ! -f "${manifest_path}" ]]; then
    echo "Could not resolve a build manifest to export." >&2
    exit 1
fi

manifest_path="$(cd "$(dirname "${manifest_path}")" && pwd)/$(basename "${manifest_path}")"

reported_run_label="$(get_metadata_value "${manifest_path}" "Run Label")"
reported_mode="$(get_metadata_value "${manifest_path}" "Mode")"
reported_iso_path="$(get_metadata_value "${manifest_path}" "Full Path")"
reported_built_at="$(get_metadata_value "${manifest_path}" "Built At")"

if [[ -z "${run_label}" ]]; then
    run_label="${reported_run_label}"
fi

if [[ -z "${iso_path}" ]]; then
    if [[ -n "${reported_iso_path}" && "${reported_iso_path}" != "not-found" && -f "${reported_iso_path}" ]]; then
        iso_path="${reported_iso_path}"
    elif compgen -G "${default_iso_dir}/*.iso" >/dev/null 2>&1; then
        iso_path="$(find "${default_iso_dir}" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
    fi
fi

if [[ -z "${iso_path}" || ! -f "${iso_path}" ]]; then
    echo "Could not resolve an ISO artifact to export." >&2
    exit 1
fi

iso_path="$(cd "$(dirname "${iso_path}")" && pwd)/$(basename "${iso_path}")"

date_stamp="$(date +%F)"
time_stamp="$(date +%Y%m%d-%H%M%S)"
label_segment="$(safe_segment "${run_label:-${reported_mode:-${mode}}}")"
out_dir="${out_dir:-${repo_root}/build/exported-handoffs/${date_stamp}/${time_stamp}-${label_segment}}"
manifest_copy_path="${out_dir}/build-manifest.md"
iso_copy_path="${out_dir}/$(basename "${iso_path}")"
handoff_manifest_path="${out_dir}/handoff-manifest.md"
iso_sha256="$(sha256sum "${iso_path}" | awk '{print $1}')"

mkdir -p "${out_dir}"
cp "${manifest_path}" "${manifest_copy_path}"
cp "${iso_path}" "${iso_copy_path}"

cat > "${handoff_manifest_path}" <<EOF
# Lumina-OS Build Handoff

- Exported At: $(date -Iseconds)
- Mode: ${reported_mode:-${mode}}
- Run Label: ${run_label:-not-recorded-yet}
- Source Build Manifest: ${manifest_path}
- Copied Build Manifest: ${manifest_copy_path}
- Source ISO Path: ${iso_path}
- Copied ISO Path: ${iso_copy_path}
- ISO File: $(basename "${iso_copy_path}")
- ISO Size Bytes: $(stat -c '%s' "${iso_copy_path}")
- ISO SHA256: ${iso_sha256}
- Reported Built At: ${reported_built_at:-not-recorded-yet}

## Next Step
- copy this entire folder into the Windows workspace
- import it there with \`powershell -ExecutionPolicy Bypass -File .\\scripts\\import-build-handoff.ps1 -HandoffPath "<copied-folder>"\`
EOF

echo "Exported Lumina-OS build handoff:"
echo "${out_dir}"
