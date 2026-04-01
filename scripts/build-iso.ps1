param(
    [string]$ProfilePath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\archiso-profile",
    [string]$WorkPath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\work",
    [string]$OutPath = "C:\Users\abdal\Downloads\AhmadOS-Rebuild\build\out",
    [ValidateSet("stable", "login-test")]
    [string]$Mode = "stable",
    [string]$RunLabel = ""
)

$validatorPath = Join-Path $PSScriptRoot "validate-profile.ps1"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedRunLabel = if ([string]::IsNullOrWhiteSpace($RunLabel)) {
    (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + $Mode + "-build"
}
else {
    $RunLabel.Trim()
}

if (Test-Path $validatorPath) {
    Write-Host "Running local Lumina-OS profile validation..."
    & $validatorPath -RepoRoot $repoRoot
    if (-not $?) {
        throw "Profile validation failed. Fix the issues above before entering the Arch build environment."
    }
    Write-Host ""
}

Write-Host "Lumina-OS build helper"
Write-Host "Profile: $ProfilePath"
Write-Host "Work:    $WorkPath"
Write-Host "Out:     $OutPath"
Write-Host "Mode:    $Mode"
Write-Host "RunLabel:$resolvedRunLabel"
Write-Host ""
Write-Host "Run this inside the Lumina-OS repo root in an Arch build environment with archiso installed:"
Write-Host "./scripts/build-iso-arch.sh --mode '$Mode' --run-label '$resolvedRunLabel'"
Write-Host ""
Write-Host "Optional Arch-side custom paths:"
Write-Host "./scripts/build-iso-arch.sh --mode '$Mode' --run-label '$resolvedRunLabel' --work './build/work/$Mode' --out './build/out/$Mode'"
Write-Host ""
Write-Host "Use the same run label for the VM cycle after the build finishes:"
Write-Host ".\scripts\start-vm-test-cycle.ps1 -Mode $Mode -RunLabel $resolvedRunLabel"
Write-Host ""
Write-Host "If the build manifest comes back from a separate Arch clone or VM, import it into this repo first:"
Write-Host ".\scripts\import-build-manifest.ps1 -ManifestPath `"C:\Path\To\build-manifest.md`""
Write-Host ""
Write-Host "If the ISO file itself comes back from that Arch environment, import it too before release prep:"
Write-Host ".\scripts\import-iso-artifact.ps1 -IsoPath `"C:\Path\To\lumina-os.iso`" -Mode $Mode -RunLabel $resolvedRunLabel"
Write-Host ""
Write-Host "Or move both together in one folder and import the complete handoff:"
Write-Host ".\scripts\import-build-handoff.ps1 -HandoffPath `"C:\Path\To\build-handoff-folder`""
