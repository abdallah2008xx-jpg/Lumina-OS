# Lumina-OS Update Center Spec

## Goal
Make updates understandable, trustworthy, and safe to approach.

## Phase 1 Role
For the first milestone, Update Center is a release-awareness surface rather than a full package manager.

## Phase 1 Scope
- show current Lumina-OS version
- show current release channel
- check GitHub releases for newer versions later
- present release notes clearly
- explain whether a restart is needed
- show the last successful update check

## Top-Level Sections
- Overview
- Available Updates
- Release Notes
- History
- Channel
- Recovery

## Overview Surface
- current version card
- channel badge
- system status summary
- `Check for updates` primary action
- signed or verified status when available

## Available Updates
- separate Lumina-OS release updates from app updates
- show estimated size and restart requirement
- explain risk level in plain language

## Release Notes
- summarize the update in human terms first
- technical details can sit in a secondary expandable area
- always show the publish date

## History
- last check time
- last successful update
- recent installed version list

## Channel Model
### Dev
- earliest builds
- unstable by design

### Alpha
- preview testing
- feature-complete but risky

### Beta
- broader testing
- mostly stable with remaining rough edges

### Stable
- recommended
- best default for normal users

## Recovery Messaging
- explain what to do if an update fails
- link to release notes and reinstall guidance
- when rollback does not exist yet, say so clearly

## Trust Rules
- never expose package jargon as the headline message
- always tell the user what changed and what to expect
- warn clearly before moving to a riskier channel

## Phase 1 Technical Direction
- start with GitHub Releases metadata
- use a local cache for the last check state
- keep UI independent from future package-repository logic

## Deferred Items
- full package transaction UI
- scheduled install windows
- rollback automation
- delta update delivery
