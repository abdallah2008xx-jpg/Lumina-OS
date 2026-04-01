# Lumina-OS Release Agent Report

## Purpose
This report turns the current Lumina-OS state into an actionable release, build, packaging, and update plan that can scale from local ISO experiments to public GitHub releases.

---

## 1. Current Project Assessment

## What already exists
- Clean project structure in `Lumina-OS`
- Arch-based `archiso` profile skeleton
- Minimal KDE Plasma + SDDM package baseline
- Early `airootfs` customization
- Build helper script for local `mkarchiso` usage
- Initial documentation for roadmap, release vision, and update strategy

## What is missing for real releases
- No defined versioning policy beyond `0.1.0-dev`
- No reproducible build environment specification
- No automated validation or smoke tests
- No CI/CD pipeline for GitHub Actions or equivalent
- No artifact signing/checksum workflow
- No release branch / tag / changelog policy
- No update channel metadata format
- No package repository strategy beyond future intent
- No installer/recovery/release support policy

## Main conclusion
The project is correctly positioned for a **stability-first pre-alpha phase**. The next best move is **not** heavy branding. It is building a repeatable pipeline that can produce the same ISO, test it, publish it, and describe what changed.

---

## 2. Recommended Release Model

## Release ladder
Use a staged release ladder instead of jumping straight to "public stable":

1. **Local dev builds**
   - built manually on the maintainer machine
   - used only for fixing boot, Plasma, and hardware basics

2. **CI snapshot builds**
   - built from GitHub Actions on pushes to `main`
   - tagged as `nightly` or `snapshot`
   - short retention, not permanent releases

3. **Pre-alpha / alpha releases**
   - manually promoted builds
   - downloadable from GitHub Releases
   - intended for VM and limited tester use

4. **Beta releases**
   - feature-complete enough for wider testing
   - stronger upgrade path expectations
   - better docs and issue reporting flow

5. **Stable public releases**
   - signed, documented, mirrored if needed
   - clear support window and update rules

## Recommendation
For Lumina-OS right now, target this sequence:
- `0.1.0-dev` = local-only
- `0.1.0-alpha.1` = first bootable public VM-focused ISO
- `0.1.0-beta.1` = first polished tester release
- `1.0.0` = first real public flagship release

---

## 3. Versioning and Naming Strategy

## Version format
Use semver-style release numbers with pre-release labels:
- `0.1.0-dev`
- `0.1.0-alpha.1`
- `0.1.0-alpha.2`
- `0.1.0-beta.1`
- `0.1.0-rc.1`
- `1.0.0`

## Build metadata
Add build metadata separately for internal tracking:
- build date
- git commit SHA
- pipeline run number

Example:
- Release version: `0.1.0-alpha.1`
- Internal build id: `0.1.0-alpha.1+20260331.shaabcdef`

## ISO naming
Use predictable names:
- `Lumina-OS-0.1.0-alpha.1-x86_64.iso`
- `Lumina-OS-0.1.0-beta.1-x86_64.iso`
- `Lumina-OS-1.0.0-x86_64.iso`

Also publish:
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.sig` later when signing is added
- release notes markdown or GitHub Release text

---

## 4. Build Pipeline Plan

## Phase A: Local reproducible build baseline
Goal: one clean documented way to build the ISO every time.

### Actions
1. Define a canonical build environment
   - Arch Linux builder host or container
   - fixed required packages: `archiso`, `git`, `bash`, `pacman-contrib`, `qemu`, `ovmf`, optionally `xorriso`

2. Add builder documentation
   - `docs/BUILD-ENVIRONMENT.md`
   - explain exact commands for local build and local test boot

3. Improve build script layout
   - keep `scripts/build-iso.ps1` for Windows-side guidance
   - add Linux-native scripts:
     - `scripts/build-iso.sh`
     - `scripts/test-iso-qemu.sh`
     - `scripts/generate-checksums.sh`

4. Make version input explicit
   - read version from one source of truth, such as:
     - `VERSION`
     - or `docs/release.json`
   - inject it into `profiledef.sh`

5. Separate output folders clearly
   - `build/work/`
   - `build/out/`
   - `build/logs/`
   - `build/test-results/`

## Exit criteria
- A clean build can be reproduced from docs
- Output ISO has predictable naming
- SHA256 checksum is generated automatically

---

## Phase B: Automated validation
Goal: stop broken ISOs before they become releases.

### Minimum validation gates
1. **Lint/config checks**
   - verify required files exist
   - verify version is valid
   - verify package list is non-empty
   - verify `profiledef.sh` contains expected fields

2. **Build success gate**
   - `mkarchiso` must complete successfully

3. **Artifact checks**
   - ISO file exists
   - checksum file exists
   - artifact size is within sane range

4. **Boot smoke test**
   - boot ISO in QEMU with OVMF
   - confirm system reaches graphical target or login manager within timeout
   - at minimum, confirm no kernel panic / initramfs failure / immediate reboot loop

5. **Basic runtime checks**
   - NetworkManager service enabled
   - SDDM service linked correctly
   - live user present

## Nice-to-have later
- screenshot capture from VM boot
- scripted login and desktop check
- journal log extraction from test VM

## Exit criteria
- Every candidate release passes automated build + basic boot validation

---

## Phase C: GitHub Actions CI/CD
Goal: build and publish candidate artifacts automatically.

## Suggested workflows

### 1. `ci-validate.yml`
Trigger:
- pull requests
- pushes to `main`

Jobs:
- repo structure checks
- version sanity checks
- shell script linting if scripts are added
- optional markdown linting

### 2. `build-nightly.yml`
Trigger:
- push to `main`
- manual dispatch

Jobs:
- build ISO in Linux runner or self-hosted Arch runner
- generate checksum
- upload artifact
- optionally publish as prerelease snapshot

### 3. `release.yml`
Trigger:
- git tag like `v0.1.0-alpha.1`

Jobs:
- build release ISO
- generate `SHA256SUMS.txt`
- create GitHub Release
- attach ISO + checksums + notes
- mark prerelease for alpha/beta/rc, full release for stable

## Important practical note
GitHub-hosted runners may not be ideal for native ArchISO workflows. Best options:
1. **Self-hosted Arch runner** for the cleanest path
2. **Containerized Arch build environment** inside GitHub Actions
3. GitHub Actions only for validation, with releases built on a controlled builder machine if runner limitations get in the way

## Recommendation
Start with:
- GitHub Actions for validation and metadata
- one trusted Arch build machine for actual ISO builds
- later promote to full CI artifact builds when the process is stable

---

## 5. GitHub Release Flow

## Branch strategy
Keep it simple early:
- `main` = active development
- `release/*` = optional stabilization branches later

## Tagging strategy
- Annotated tags only
- Prefix with `v`
- Examples:
  - `v0.1.0-alpha.1`
  - `v0.1.0-beta.1`
  - `v1.0.0`

## Release checklist
Before tagging:
1. version bumped
2. changelog updated
3. build passes locally or in CI
4. smoke test passes
5. checksum generated
6. release notes drafted

## Release contents
Every GitHub Release should include:
- ISO file
- SHA256 checksum file
- release notes
- known issues
- VM test status
- hardware support disclaimer for early releases

## Changelog policy
Create `CHANGELOG.md` using simple categories:
- Added
- Changed
- Fixed
- Known issues

## Release promotion rules
- `alpha`: boots and reaches a usable desktop in VM
- `beta`: stable enough for broader testers, core UX mostly coherent
- `stable`: installer/recovery/docs/update story are ready enough for real users

---

## 6. Update Channel Strategy

## Short-term reality
For a live ISO project, users do **not** have a safe OTA story yet. Pretending otherwise would be a mistake. Early Lumina-OS should treat updates as:
- new ISO downloads
- manual reinstall or manual upgrade guidance

## Recommended channels
Define channels now even before in-OS updater exists:
- `dev`
- `alpha`
- `beta`
- `stable`

## Channel behavior
- **dev**: every successful snapshot build, unstable
- **alpha**: milestone testing, boot and UX validation
- **beta**: feature polishing and regression fixing
- **stable**: publicly recommended builds only

## Channel metadata format
Add a machine-readable file later, such as `releases/channels.json` in the repo or website:

```json
{
  "stable": {"version": "1.0.0", "url": "...", "sha256": "..."},
  "beta": {"version": "0.9.0-beta.2", "url": "...", "sha256": "..."},
  "alpha": {"version": "0.1.0-alpha.3", "url": "...", "sha256": "..."},
  "dev": {"version": "0.1.0-dev+20260331", "url": "...", "sha256": "..."}
}
```

This can later power an Lumina-OS Update Center.

## Update Center roadmap
Do not build it yet, but plan for it:
1. read channel metadata
2. compare installed version
3. show release notes
4. offer download or guided upgrade path
5. later integrate package repo updates

---

## 7. Packaging Strategy

## Stage 1: ISO-first packaging
Right now the main product is the ISO. That is correct.

### What to package now
- archiso profile
- branding assets
- system defaults
- helper scripts
- release notes and checksums

### Principle
Keep Lumina-OS-specific customization in the repo, not hand-edited inside build leftovers.

## Stage 2: Lumina-OS package split
As the project matures, split customizations into discrete packages instead of baking everything directly into `airootfs`.

Recommended future package families:
- `ahmados-branding`
- `ahmados-defaults`
- `ahmados-wallpapers`
- `ahmados-sddm-theme`
- `ahmados-plasma-layout`
- `ahmados-firstboot`
- `ahmados-update-center`

## Why this matters
Packaging custom components makes it easier to:
- update systems after install
- track versions cleanly
- roll back bad changes
- reuse the same components in ISO and installed systems

## Stage 3: Lumina-OS package repository
Only start this after alpha quality is real.

### Recommended repo structure later
- `core-ahmados` for critical distro packages
- `extra-ahmados` for desktop experience packages
- optional `testing-ahmados` aligned to beta/dev channels

## Important warning
Do **not** fork half of Arch unnecessarily. Lumina-OS should package only what is truly Lumina-OS-specific and inherit as much as possible from upstream Arch.

---

## 8. Security and Trust Plan

## Minimum required before public releases
1. publish SHA256 checksums
2. use Git tags consistently
3. keep release notes honest about risk
4. document build provenance

## Required before stable releases
1. GPG-sign tags
2. sign checksums or artifacts
3. protect release workflow secrets
4. have reproducible build notes
5. define supported hardware/test scope clearly

## Recommended later
- SBOM or package manifest per release
- attestation/provenance from CI
- secure boot strategy investigation

---

## 9. Milestones: From Local Builds to Public Releases

## Milestone 0 â€” Project hardening
Goal: make the repo release-aware.

### Deliverables
- `VERSION` file
- `CHANGELOG.md`
- `docs/BUILD-ENVIRONMENT.md`
- `docs/RELEASE-PROCESS.md`
- Linux build/test scripts
- checksum generation script

### Success condition
One documented local build produces a named ISO and checksum.

---

## Milestone 1 â€” First repeatable local ISO
Goal: same ISO pipeline works more than once.

### Deliverables
- successful `mkarchiso` build
- QEMU boot test
- proof that SDDM appears
- logs captured from test session

### Success condition
The maintainer can rebuild and retest after changes without improvising.

---

## Milestone 2 â€” Internal pre-alpha snapshot pipeline
Goal: start release discipline without public pressure.

### Deliverables
- GitHub repo initialized if not already
- CI validation workflow
- nightly/snapshot artifact build path
- automatic checksums
- initial changelog process

### Success condition
Every mainline change can be validated and optionally produce a snapshot artifact.

---

## Milestone 3 â€” First public alpha release
Goal: publish the first serious Lumina-OS test ISO.

### Deliverables
- tagged release `v0.1.0-alpha.1`
- GitHub Release with ISO + checksum
- release notes with known issues
- VM support statement
- tester instructions for reporting bugs

### Success condition
Testers can download, verify, boot, and report issues with a known release identifier.

---

## Milestone 4 â€” Beta readiness
Goal: move from "boots in VM" to "usable test distro".

### Deliverables
- improved branding and desktop defaults
- first-run flow or welcome app
- more hardware validation
- clearer installation story
- channel metadata format designed or implemented

### Success condition
Lumina-OS is stable enough that non-developer testers can try it without constant handholding.

---

## Milestone 5 â€” Stable release foundation
Goal: be credible as a public distro project.

### Deliverables
- signed releases
- package split for Lumina-OS-specific components
- initial Lumina-OS package repository plan or implementation
- update-center design tied to real channel metadata
- installer/recovery/documentation maturity

### Success condition
The project can support a public stable release process instead of one-off ISO drops.

---

## 10. Immediate Action List

## Highest-priority next steps
1. Create `VERSION` file and make `profiledef.sh` read from it
2. Add `CHANGELOG.md`
3. Add `docs/BUILD-ENVIRONMENT.md`
4. Add Linux-native `scripts/build-iso.sh`
5. Add `scripts/generate-checksums.sh`
6. Add `scripts/test-iso-qemu.sh`
7. Define release naming rules in `docs/RELEASE-PROCESS.md`
8. Add a GitHub Actions validation workflow
9. Build and test the first local ISO successfully
10. Only after that, prepare `0.1.0-alpha.1`

## Strong recommendation
Treat the next release target as:
- **not** a polished public distro
- **yes** a disciplined, bootable, testable pre-alpha foundation

That is the right move. Lumina-OS needs a trustworthy pipeline before it needs flashy release marketing.

---

## 11. Proposed File Additions

Recommended new files for the repo:

```text
Lumina-OS/
  VERSION
  CHANGELOG.md
  .github/workflows/ci-validate.yml
  .github/workflows/build-nightly.yml
  .github/workflows/release.yml
  docs/BUILD-ENVIRONMENT.md
  docs/RELEASE-PROCESS.md
  docs/CHANNELS.md
  scripts/build-iso.sh
  scripts/test-iso-qemu.sh
  scripts/generate-checksums.sh
```

---

## 12. Final Recommendation

The best strategy for Lumina-OS is:
- **ISO-first**
- **stability-first**
- **GitHub Releases first, OTA later**
- **package Lumina-OS-specific parts only**
- **use alpha/beta/stable channels before promising seamless in-place upgrades**

In plain terms: build a release pipeline that people can trust, then build an update system on top of that trust.
