# Update Strategy

## Stage 1 â€” GitHub-based delivery
- Host source on GitHub
- Publish ISOs and checksums in GitHub Releases
- Maintain changelogs per release
- Let users manually download releases first

## Stage 2 â€” In-system awareness
- Add an Lumina-OS Update Center
- Check GitHub Releases API for new versions/channels
- Show release notes and download links

## Stage 3 â€” Managed package updates
- Create Lumina-OS package repository
- Ship Lumina-OS-specific packages through the repo
- Keep larger system updates aligned with the chosen package strategy

## Stage 4 â€” Guided update UX
- Channel selection: dev/alpha/beta/stable
- Update notifications
- Rollback/recovery planning
- Signed artifacts and trust model
