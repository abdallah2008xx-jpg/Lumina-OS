# Update Strategy

## Stage 1 — GitHub-based delivery
- Host source on GitHub
- Publish ISOs and checksums in GitHub Releases
- Maintain changelogs per release
- Let users manually download releases first

## Stage 2 — In-system awareness
- Add an AhmadOS Update Center
- Check GitHub Releases API for new versions/channels
- Show release notes and download links

## Stage 3 — Managed package updates
- Create AhmadOS package repository
- Ship AhmadOS-specific packages through the repo
- Keep larger system updates aligned with the chosen package strategy

## Stage 4 — Guided update UX
- Channel selection: dev/alpha/beta/stable
- Update notifications
- Rollback/recovery planning
- Signed artifacts and trust model
