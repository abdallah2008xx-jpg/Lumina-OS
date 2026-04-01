param(
    [Parameter(Mandatory = $true)]
    [string]$VmName,
    [string]$OutputPath = "",
    [string]$GuestUser = "live",
    [string]$GuestPassword = "",
    [string]$VBoxManagePath = "",
    [switch]$ForceGuestCapture,
    [switch]$OutputPathOnly,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Resolve-VBoxManagePath {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (-not (Test-Path $RequestedPath)) {
            throw "VBoxManage path does not exist: $RequestedPath"
        }

        return (Resolve-Path $RequestedPath).Path
    }

    $command = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $defaultPath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    if (Test-Path $defaultPath) {
        return $defaultPath
    }

    throw "Unable to locate VBoxManage.exe. Install VirtualBox or pass -VBoxManagePath."
}

function Test-IsUsefulPng {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    return ((Get-Item $Path).Length -gt 6000)
}

$resolvedVBoxManagePath = Resolve-VBoxManagePath -RequestedPath $VBoxManagePath
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $shotsDir = Join-Path $RepoRoot ("build\virtualbox-shots\" + $VmName)
    New-Item -ItemType Directory -Force -Path $shotsDir | Out-Null
    $OutputPath = Join-Path $shotsDir ("guest-fallback-" + $timestamp + ".png")
}
else {
    $outputDir = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }
}

$hostAttemptPath = Join-Path ([System.IO.Path]::GetTempPath()) ("lumina-vbox-host-shot-" + $timestamp + ".png")
$captureSource = "guest-fallback"

try {
    & $resolvedVBoxManagePath controlvm $VmName screenshotpng $hostAttemptPath | Out-Null
}
catch {
    Remove-Item -Force -LiteralPath $hostAttemptPath -ErrorAction SilentlyContinue
    throw
}

if (-not $ForceGuestCapture.IsPresent -and (Test-IsUsefulPng -Path $hostAttemptPath)) {
    Copy-Item -Force -LiteralPath $hostAttemptPath -Destination $OutputPath
    $captureSource = "host-screenshotpng"
}
else {
    $remotePath = "/tmp/lumina-vbox-capture-$timestamp.png"

    $guestRunOutput = & $resolvedVBoxManagePath guestcontrol $VmName run `
        --exe /usr/local/bin/lumina-capture-screenshot `
        --username $GuestUser `
        --password $GuestPassword `
        --wait-stdout `
        --wait-stderr `
        -- `
        /usr/local/bin/lumina-capture-screenshot `
        --output $remotePath 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Guest screenshot helper failed: $guestRunOutput"
    }

    $copyOutput = & $resolvedVBoxManagePath guestcontrol $VmName copyfrom `
        --username $GuestUser `
        --password $GuestPassword `
        $remotePath `
        $OutputPath 2>&1

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutputPath)) {
        throw "Unable to copy the guest screenshot back to the host: $copyOutput"
    }

    & $resolvedVBoxManagePath guestcontrol $VmName run `
        --exe /usr/bin/rm `
        --username $GuestUser `
        --password $GuestPassword `
        --wait-stdout `
        --wait-stderr `
        -- `
        /usr/bin/rm `
        -f `
        $remotePath | Out-Null
}

Remove-Item -Force -LiteralPath $hostAttemptPath -ErrorAction SilentlyContinue

if ($OutputPathOnly) {
    Write-Output $OutputPath
}
else {
    Write-Host "Captured Lumina-OS screenshot from VirtualBox."
    Write-Host "VM Name: $VmName"
    Write-Host "Source:  $captureSource"
    Write-Host "Output:  $OutputPath"
}
