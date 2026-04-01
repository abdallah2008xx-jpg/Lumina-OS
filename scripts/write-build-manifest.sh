#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
AhmadOS build manifest writer

Usage:
  ./scripts/write-build-manifest.sh \
    --mode stable|login-test \
    --profile PATH \
    --stage PATH \
    --work PATH \
    --out PATH \
    [--manifest-root PATH]
EOF
}

mode=""
profile_path=""
stage_path=""
work_path=""
out_path=""
manifest_root=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            mode="${2:-}"
            shift 2
            ;;
        --profile)
            profile_path="${2:-}"
            shift 2
            ;;
        --stage)
            stage_path="${2:-}"
            shift 2
            ;;
        --work)
            work_path="${2:-}"
            shift 2
            ;;
        --out)
            out_path="${2:-}"
            shift 2
            ;;
        --manifest-root)
            manifest_root="${2:-}"
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

if [[ -z "${mode}" || -z "${profile_path}" || -z "${stage_path}" || -z "${work_path}" || -z "${out_path}" ]]; then
    echo "Missing required arguments." >&2
    usage >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
manifest_root="${manifest_root:-${repo_root}/status/builds}"

mkdir -p "${manifest_root}"

hostname_value="$(hostname 2>/dev/null || printf '%s' 'unknown')"
kernel_value="$(uname -r 2>/dev/null || printf '%s' 'unknown')"
user_value="$(id -un 2>/dev/null || printf '%s' 'unknown')"
archiso_version="$(pacman -Q archiso 2>/dev/null | awk '{print $2}' || printf '%s' 'unknown')"
git_version="$(git --version 2>/dev/null | awk '{print $3}' || printf '%s' 'unknown')"

latest_iso=""
if compgen -G "${out_path}/*.iso" >/dev/null 2>&1; then
    latest_iso="$(find "${out_path}" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
fi

built_at="$(date -Iseconds)"
manifest_stamp="$(date +%Y%m%d-%H%M%S)"
manifest_file="${manifest_root}/build-${manifest_stamp}-${mode}.md"

iso_name="not-found"
iso_size_bytes="unknown"
iso_sha256="unavailable"

if [[ -n "${latest_iso}" && -f "${latest_iso}" ]]; then
    iso_name="$(basename "${latest_iso}")"
    if command -v stat >/dev/null 2>&1; then
        iso_size_bytes="$(stat -c '%s' "${latest_iso}")"
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        iso_sha256="$(sha256sum "${latest_iso}" | awk '{print $1}')"
    fi
fi

cat > "${manifest_file}" <<EOF
# AhmadOS Build Manifest

- Built At: ${built_at}
- Mode: ${mode}
- Profile Path: ${profile_path}
- Stage Path: ${stage_path}
- Work Path: ${work_path}
- Output Path: ${out_path}

## Build Environment
- Hostname: ${hostname_value}
- Kernel: ${kernel_value}
- User: ${user_value}
- archiso Version: ${archiso_version}
- git Version: ${git_version}

## ISO Artifact
- File: ${iso_name}
- Full Path: ${latest_iso:-not-found}
- Size Bytes: ${iso_size_bytes}
- SHA256: ${iso_sha256}

## Next Verification
- Boot the ISO in a VM before deeper branding changes
- Record a VM test report under \`status/vm-tests/\`
- Review the AhmadOS firstboot report inside the live session
EOF

echo "Build manifest written to: ${manifest_file}"
