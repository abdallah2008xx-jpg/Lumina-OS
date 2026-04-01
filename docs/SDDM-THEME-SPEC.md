# Lumina-OS SDDM Theme Spec

## Goal
Make login feel premium and calm without adding fragile boot-time complexity.

## Layout Direction
- centered or slightly lowered login card
- large time and date visible above the card
- soft environmental wallpaper background
- subtle dim overlay behind the auth surface

## Required Elements
- Lumina-OS wordmark
- user avatar
- password field
- session picker
- keyboard layout indicator
- restart and shutdown actions

## Visual Tone
- dark glass surface over a calmer wallpaper
- ivory typography on deep blue layers
- copper used sparingly for focus and hover highlights
- no widget clutter, news, or system trivia

## Accessibility
- clear focus rings
- visible keyboard layout state
- strong contrast on the password field
- enough spacing for touchpad and mouse use on high DPI displays

## Phase 1 Technical Constraints
- keep it layered on top of a stable SDDM base
- avoid heavy animations and external dependencies
- keep asset count low
- allow a fallback stock theme during early ISO testing

## Wallpaper Guidance
- prefer the darker wallpaper family for login
- preserve enough empty visual space for the card and time/date
- avoid noisy textures that interfere with text legibility

## Implementation Notes
- first theme should ship with static assets only
- use the Lumina-OS wallpaper pack and brand tokens directly
- keep theme sizing reliable for 1366x768 through 4K
