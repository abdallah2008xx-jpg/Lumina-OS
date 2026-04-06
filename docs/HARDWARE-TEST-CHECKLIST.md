# Lumina-OS Hardware Test Checklist

Use this checklist when validating a real device, not just a VM.

## Goal
- prove that Lumina-OS can boot on a real machine
- capture one hardware-readiness report from the live or installed session
- verify Wi-Fi, audio, graphics, storage, and power basics before release

## Recommended Flow
1. Boot the latest Lumina-OS ISO on a real device.
2. Reach the live Plasma session or the installed desktop.
3. Run `Lumina-OS Hardware Readiness Check`.
4. Save the generated report path and copy it into the matching hardware test notes.
5. Record any blocker immediately if a core subsystem does not work.

## Live Session Checks
1. Confirm the system boots on the real device.
2. Confirm display output is stable and the desktop fits the screen.
3. Confirm keyboard and touchpad or mouse work.
4. Confirm `Lumina-OS Hardware Readiness Check` opens and writes a report.

## Core Hardware Checks
1. Confirm Wi-Fi hardware is detected.
2. Confirm the machine can connect to a real network if Wi-Fi is expected.
3. Confirm audio output works through at least one sink.
4. Confirm graphics look stable with no obvious corruption.
5. Confirm storage devices are detected correctly.
6. Confirm suspend, shutdown, and reboot behave as expected.

## Portable Device Checks
1. Confirm battery state is detected if the device is a laptop.
2. Confirm AC power and battery transitions look sane.
3. Confirm brightness keys work if the device exposes them.

## Optional Checks
1. Confirm Bluetooth controller detection if the device has Bluetooth.
2. Confirm webcam or microphone if they matter for the release target.

## Evidence
- one hardware report under `~/.local/state/ahmados/hardware-readiness-report.md`
- one hardware test note under `status/hardware-tests/YYYY-MM-DD/`
- screenshots only when they add real evidence
