#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
AhmadOS Arch build-environment bootstrap

Usage:
  ./scripts/bootstrap-arch-build-env.sh [--install] [--skip-validator]

Options:
  --install         Install any missing packages with pacman
  --skip-validator  Do not run the AhmadOS profile validator after checks
EOF
}

install_missing=0
skip_validator=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            install_missing=1
            shift
            ;;
        --skip-validator)
            skip_validator=1
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

if ! command -v pacman >/dev/null 2>&1; then
    echo "This helper must be run inside an Arch-based environment with pacman available." >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
validator_path="${repo_root}/scripts/validate-profile.sh"

required_packages=(
    archiso
    git
)

missing_packages=()

for package_name in "${required_packages[@]}"; do
    if ! pacman -Q "${package_name}" >/dev/null 2>&1; then
        missing_packages+=("${package_name}")
    fi
done

echo "AhmadOS Arch build-environment bootstrap"
echo "Repo root: ${repo_root}"
echo ""

if [[ ${#missing_packages[@]} -eq 0 ]]; then
    echo "All required Arch build packages are already installed."
else
    echo "Missing packages: ${missing_packages[*]}"

    if [[ ${install_missing} -eq 1 ]]; then
        pacman_runner=(sudo)
        if [[ $(id -u) -eq 0 ]]; then
            pacman_runner=()
        elif ! command -v sudo >/dev/null 2>&1; then
            echo "sudo is required to install missing packages as a non-root user." >&2
            exit 1
        fi

        echo ""
        echo "Installing missing packages..."
        "${pacman_runner[@]}" pacman -Sy --needed "${missing_packages[@]}"
    else
        echo ""
        echo "To install them automatically, rerun:"
        echo "./scripts/bootstrap-arch-build-env.sh --install"
    fi
fi

if [[ ${skip_validator} -eq 0 && -f "${validator_path}" ]]; then
    echo ""
    echo "Running AhmadOS profile validation..."
    bash "${validator_path}" --repo-root "${repo_root}" --profile "${repo_root}/archiso-profile"
fi

echo ""
echo "Next step:"
echo "./scripts/build-iso-arch.sh --mode stable"
