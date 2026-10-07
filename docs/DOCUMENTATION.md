# Tempo — Documentation (as built)

> This is the detailed reference for what the app does **right now**, and how it's built. It's updated after every change (rule in `CLAUDE.md`).
>
> For what the app is **meant** to do, see `docs/SPEC.md`. If the two disagree, SPEC.md describes the intent, and the mismatch is a bug to raise.

## How to maintain this file

- **Sections:** one per feature, with the same `F-` ID and title as in SPEC.md. Edit only the sections your change touched.
- **After every change,** update the section's `Status` and `Last updated` lines with the date and the task ID or change.
- **Status values:** `Not built` · `Partly built (T-xx, …)` · `Built`.
- **Fill in the template below** once a feature is partly or fully built. Describe what is true in the code, including:
  - defaults and limits;
  - exact copy;
  - edge cases;
  - which files implement it.
- **If this file grows past about 3,000 lines,** split it into `docs/features/F-xx-name.md` files using the same template, and turn this file into an index.

### Section template

```markdown
## F-xx · Name
Status: Built · Last updated: 2026-10-14 · T-12

### What it does
One or two sentences.

### Behavior
- Every rule, default, limit and edge case, as implemented.
- Exact user-facing text in quotes.

### Data
Which tables and fields it reads or writes. Device-only state it uses.

### Implementation (iOS)
- Views: Tempo/Views/...
- Managers: Shared/Managers/...
- Rules: Packages/Core/Sources/Core/...
- Widgets and intents: TempoWidgets/..., Shared/Intents/...

### Tests
- File and what it covers.

### Known gaps
- Anything not yet matching SPEC, with the task that will fix it.
```

---

## App overview

Status: Partly built (T-01) · Last updated: 2026-10-07 · T-01, D-052

### What it does
Only the project skeleton exists. No features are live yet. The app opens to a placeholder screen, and the widget gallery offers one placeholder widget.

### Behavior
- **App:** a single centered screen with a clock symbol, the title "Tempo" and the message "The app is being built." There's nothing to tap.
- **Widget:** one small widget, listed in the gallery as "Tempo" with the description "A placeholder until the real widgets are built." It shows a clock symbol and "Tempo", and never refreshes.
- **iPhone** runs in portrait only. **iPad** supports all four orientations.

### Project and targets
| Item | Value |
|---|---|
| Project / shared scheme | `Tempo.xcodeproj` / `Tempo` (builds the app and extension; tests `TempoTests`) |
| App target | `Tempo`, bundle ID `com.applab.tempo`, display name "Tempo" |
| Widget extension | `TempoWidgets`, bundle ID `com.applab.tempo.widgets`, embedded in the app |
| App tests | `TempoTests`, bundle ID `com.applab.tempo.tests`, hosted in the app |
| Logic package | `Packages/Core` (Swift 6 tools, iOS 17 and macOS 14), linked into the app and the extension |
| Deployment target | iOS 17.0, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Swift | App, extension and tests use Swift 5 mode with strict concurrency set to `complete`. Default actor isolation stays `nonisolated` (D-047). |
| App Group | `group.com.applab.tempo`, in both targets' entitlements |
| URL scheme | `tempo` (app `Info.plist`) |
| Background refresh | `UIBackgroundModes = [fetch]` and `BGTaskSchedulerPermittedIdentifiers = [com.applab.tempo.refresh]`. Nothing is registered yet; that comes in T-21. |
| Signing | Automatic, team `QAUG82L94Y` |

The folder layout matches ios.md §3. Empty folders hold a `.gitkeep`, which is kept out of the bundles (D-048). `Tempo/`, `TempoWidgets/`, `Shared/` and `TempoTests/` are folder-synchronized groups: a file added on disk joins its target automatically. `Shared/` belongs to both the app and the extension.

### Implementation (iOS)
- App: `Tempo/App/TempoApp.swift`, `Tempo/Views/Root/RootView.swift` (placeholder until T-09)
- Widget: `TempoWidgets/TempoWidgetsBundle.swift`, `TempoWidgets/Widgets/Placeholder/` (`PlaceholderWidget`, `PlaceholderProvider`, `PlaceholderEntry`; until T-23)
- Strings: `Tempo/Resources/Localizable.xcstrings` and `TempoWidgets/Resources/Localizable.xcstrings` (D-046)
- Config: `Tempo/Info.plist`, `Tempo/Tempo.entitlements`, `TempoWidgets/Info.plist`, `TempoWidgets/TempoWidgets.entitlements`, `.swift-format` (D-049)
- Core: `Packages/Core/Sources/Core/CorePlaceholder.swift` (until T-02)

### Tests
- `TempoTests/ProjectConfigurationTests.swift`: the app's bundle ID, the `tempo` URL scheme, the background refresh settings, the App Group container and the embedded extension's bundle ID.
- `Packages/Core/Tests/CoreTests/CorePlaceholderTests.swift`: one placeholder test (until T-02).

### Known gaps
- Every feature, F-01 to F-26, is still to be built (T-02 onward).
- Tests run on the latest installed simulator (iOS 27.0), not on iOS 17, because Xcode 27 can't install iOS 17 runtimes (D-052). The deployment target is still iOS 17.0, so the compiler rejects newer APIs used without an availability check.

---

## F-01 · Task types
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-01._

## F-02 · Timing and parts of the day
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-02._

## F-03 · Habit schedules and goals
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-03._

## F-04 · Daily cycle and status
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-04._

## F-05 · Time tracking
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-05._

## F-06 · Timer
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-06._

## F-07 · Notifications
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-07._

## F-08 · Missed tasks
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-08._

## F-09 · Navigation and app structure
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-09._

## F-10 · Today screen
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-10._

## F-11 · Tasks tab
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-11._

## F-12 · History
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-12._

## F-13 · Habit detail
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-13._

## F-14 · Stats
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-14._

## F-15 · Task editor
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-15._

## F-16 · Settings
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-16._

## F-17 · Widgets: general rules
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-17._

## F-18 · Timer widget (small)
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-18._

## F-19 · Day widget (medium)
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-19._

## F-20 · Focus widget (medium)
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-20._

## F-21 · Now widget (large)
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-21._

## F-22 · Lock Screen widgets
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-22._

## F-23 · First-launch guide
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-23._

## F-24 · Empty states
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-24._

## F-25 · iPad
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-25._

## F-26 · Data and future sync
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-26._
