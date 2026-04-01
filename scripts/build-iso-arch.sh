#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
AhmadOS Arch build helper

Usage:
  ./scripts/build-iso-arch.sh [--mode stable|login-test] [--profile PATH] [--work PATH] [--out PATH] [--stage-root PATH] [--keep-stage]

Modes:
  stable      Build the live ISO with autologin enabled for the live session
  login-test  Build the live ISO with manual SDDM login enabled for theme/session testing
EOF
}

mode="stable"
profile_path=""
work_path=""
out_path=""
stage_root=""
keep_stage=0

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
        --work)
            work_path="${2:-}"
            shift 2
            ;;
        --out)
            out_path="${2:-}"
            shift 2
            ;;
        --stage-root)
            stage_root="${2:-}"
            shift 2
            ;;
        --keep-stage)
            keep_stage=1
            shift
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

profile_path="${profile_path:-${repo_root}/archiso-profile}"
work_path="${work_path:-${repo_root}/build/work/${mode}}"
out_path="${out_path:-${repo_root}/build/out/${mode}}"
stage_root="${stage_root:-${repo_root}/build/stage}"
validator_path="${repo_root}/scripts/validate-profile.sh"
manifest_writer="${repo_root}/scripts/write-build-manifest.sh"

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "mkarchiso is required but was not found in PATH." >&2
    exit 1
fi

if [[ -f "${validator_path}" ]]; then
    echo "Running AhmadOS profile validation..."
    bash "${validator_path}" --repo-root "${repo_root}" --profile "${profile_path}"
    echo ""
fi

mkdir -p "${work_path}" "${out_path}" "${stage_root}"

stage_dir="$(mktemp -d "${stage_root}/ahmados-${mode}.XXXXXX")"
trap 'if [[ ${keep_stage} -eq 0 ]]; then rm -rf "${stage_dir}"; else echo "Staged profile kept at: ${stage_dir}"; fi' EXIT

echo "AhmadOS Arch build helper"
echo "Mode:    ${mode}"
echo "Profile: ${profile_path}"
echo "Stage:   ${stage_dir}"
echo "Work:    ${work_path}"
echo "Out:     ${out_path}"
echo ""

cp -a "${profile_path}/." "${stage_dir}/"

case "${mode}" in
    stable)
        cp "${profile_path}/build-variants/sddm/stable-autologin.conf" \
           "${stage_dir}/airootfs/etc/sddm.conf.d/autologin.conf"
        ;;
    login-test)
        cp "${profile_path}/build-variants/sddm/manual-login.conf" \
           "${stage_dir}/airootfs/etc/sddm.conf.d/autologin.conf"
        ;;
esac

echo "Running mkarchiso..."
mkarchiso -v -w "${work_path}" -o "${out_path}" "${stage_dir}"

if [[ -f "${manifest_writer}" ]]; then
    echo ""
    echo "Writing build manifest..."
    bash "${manifest_writer}" \
        --mode "${mode}" \
        --profile "${profile_path}" \
        --stage "${stage_dir}" \
        --work "${work_path}" \
        --out "${out_path}"
fi

echo ""
echo "Build finished."
echo "Mode used: ${mode}"
echo "Output directory: ${out_path}"
