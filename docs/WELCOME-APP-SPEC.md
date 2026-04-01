# AhmadOS Welcome App Spec

## Purpose
Orient new users in under five minutes without overwhelming them.

## Product Role
The Welcome app is the first guided product surface after login.
It should introduce AhmadOS language, appearance choices, and key next actions.

## Phase 1 Scope
- lightweight first-run shell
- language selection
- appearance mode selection
- layout preset preview
- essential app shortcuts
- update and safety explanation
- final quick-launch page

## Information Architecture
1. Welcome
2. Language
3. Appearance
4. Desktop Layout
5. Essentials
6. Updates and Safety
7. Ready

## Screen Notes
### 1. Welcome
- show AhmadOS thesis in one short sentence
- present Arabic and English as equal options
- allow `Start` and `Skip for now`

### 2. Language
- highlight current display language
- show a short preview paragraph in the selected language
- expose RTL preview for Arabic

### 3. Appearance
- light and dark preview cards
- accent color choices from the AhmadOS palette
- wallpaper family preview

### 4. Desktop Layout
- compare `Balanced`, `Classic`, and `Minimal`
- explain each in plain language
- show a small visual preview of taskbar behavior

### 5. Essentials
- shortcuts to Browser, Files, Store, Settings
- optional future section for recommended apps

### 6. Updates and Safety
- explain release channels in plain language
- show that stable is recommended
- explain restart expectations and recovery visibility

### 7. Ready
- primary CTA: `Go to desktop`
- secondary quick actions: open Store, open Settings, check for updates

## Copy Tone
- confident
- plain-language
- no Linux jargon
- short paragraphs only

## Component Rules
- visible progress stepper
- one main action per screen
- persistent `Back` and `Skip for now`
- hero illustration or abstract panel on major screens

## Accessibility and Localization
- keyboard navigable
- high contrast for primary actions
- no text baked into images
- full RTL support from the first version

## Phase 1 Technical Direction
- preferred UI layer: Qt/QML with Kirigami-style structure
- keep data local and static at first
- store selections in a small local config file
- relaunchable later from the app launcher

## Deferred Items
- account sign-in
- cloud sync
- recommended app bundles by persona
- richer onboarding analytics
