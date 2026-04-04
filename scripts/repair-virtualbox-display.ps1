param(
    [Parameter(Mandatory = $true)]
    [string]$VmName,
    [int]$Width = 1366,
    [int]$Height = 768,
    [string]$VBoxManagePath = ""
)

$ErrorActionPreference = "Stop"

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

$resolvedVBoxManagePath = Resolve-VBoxManagePath -RequestedPath $VBoxManagePath
$vmInfo = & $resolvedVBoxManagePath showvminfo $VmName --machinereadable 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read VM info for: $VmName"
}

$stateLine = $vmInfo | Where-Object { $_ -like 'VMState=*' } | Select-Object -First 1
$isRunning = $stateLine -match 'VMState="running"'
$safeHint = "$Width,$Height"

& $resolvedVBoxManagePath setextradata $VmName GUI/ScaleFactor 1.0 | Out-Null
& $resolvedVBoxManagePath setextradata $VmName GUI/LastGuestSizeHint $safeHint | Out-Null
& $resolvedVBoxManagePath setextradata $VmName GUI/LastNormalWindowPosition "40,40,1480,920" | Out-Null

if ($isRunning) {
    & $resolvedVBoxManagePath controlvm $VmName setvideomodehint $Width $Height 32 | Out-Null
}
else {
    & $resolvedVBoxManagePath modifyvm $VmName --graphicscontroller VBoxSVGA --vram 128 | Out-Null
}

Write-Host "Repaired VirtualBox display sizing for Lumina-OS."
Write-Host "VM Name:  $VmName"
Write-Host "Hint:     $safeHint"
Write-Host "Running:  $isRunning"
