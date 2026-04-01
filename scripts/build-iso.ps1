param(
    [string]$ProfilePath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\archiso-profile",
    [string]$WorkPath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\work",
    [string]$OutPath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\out",
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable"
)

$validatorPath = Join-Path $PSScriptRoot "validate-profile.ps1"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (Test-Path $validatorPath) {
    Write-Host "Running local AhmadOS profile validation..."
    & $validatorPath -RepoRoot $repoRoot
    if (-not $?) {
        throw "Profile validation failed. Fix the issues above before entering the Arch build environment."
    }
    Write-Host ""
}

Write-Host "AhmadOS build helper"
Write-Host "Profile: $ProfilePath"
Write-Host "Work:    $WorkPath"
Write-Host "Out:     $OutPath"
Write-Host "Mode:    $Mode"
Write-Host ""
Write-Host "Run this inside the AhmadOS repo root in an Arch build environment with archiso installed:"
Write-Host "./scripts/build-iso-arch.sh --mode '$Mode'"
Write-Host ""
Write-Host "Optional Arch-side custom paths:"
Write-Host "./scripts/build-iso-arch.sh --mode '$Mode' --work './build/work/$Mode' --out './build/out/$Mode'"
