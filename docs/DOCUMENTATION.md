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

Status: Partly built (T-01) · Last updated: 2026-10-07 · T-03

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
| Swift | App, extension and tests use Swift 5 mode with strict concurrency set to `complete` and `InferSendableFromCaptures` on (D-055). Default actor isolation stays `nonisolated` (D-047). |
| App Group | `group.com.applab.tempo`, in both targets' entitlements |
| URL scheme | `tempo` (app `Info.plist`) |
| Background refresh | `UIBackgroundModes = [fetch]` and `BGTaskSchedulerPermittedIdentifiers = [com.applab.tempo.refresh]`. Nothing is registered yet; that comes in T-21. |
| Signing | Automatic, team `QAUG82L94Y` |

The folder layout matches ios.md §3. Empty folders hold a `.gitkeep`, which is kept out of the bundles (D-048). `Tempo/`, `TempoWidgets/`, `Shared/` and `TempoTests/` are folder-synchronized groups: a file added on disk joins its target automatically. `Shared/` belongs to both the app and the extension.

### Implementation (iOS)
- App: `Tempo/App/TempoApp.swift` (opens the store, or shows the store error screen; see F-26), `Tempo/Views/Root/RootView.swift` (placeholder until T-09)
- Widget: `TempoWidgets/TempoWidgetsBundle.swift`, `TempoWidgets/Widgets/Placeholder/` (`PlaceholderWidget`, `PlaceholderProvider`, `PlaceholderEntry`; until T-23)
- Strings: `Tempo/Resources/Localizable.xcstrings` and `TempoWidgets/Resources/Localizable.xcstrings` (D-046)
- Config: `Tempo/Info.plist`, `Tempo/Tempo.entitlements`, `TempoWidgets/Info.plist`, `TempoWidgets/TempoWidgets.entitlements`, `.swift-format` (D-049)

### Tests
- `TempoTests/ProjectConfigurationTests.swift`: the app's bundle ID, the `tempo` URL scheme, the background refresh settings, the App Group container and the embedded extension's bundle ID.
- `Core` tests: see the feature sections (T-02 onward).

### Known gaps
- Every feature, F-01 to F-26, is still to be built (T-02 onward).
- Tests run on the latest installed simulator (iOS 27.0), not on iOS 17, because Xcode 27 can't install iOS 17 runtimes (D-052). The deployment target is still iOS 17.0, so the compiler rejects newer APIs used without an availability check.

---

## F-01 · Task types
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-01._

## F-02 · Timing and parts of the day
Status: Partly built (T-02) · Last updated: 2026-10-07 · T-02

### What it does
The rules for days, weekdays and parts of the day exist in `Core`. Nothing in the app uses them yet.

### Behavior
- **Day keys** are `yyyymmdd` integers (`DayKey`). They convert to the day's first moment and back in any calendar. Adding days, counting days between two keys and finding a day's weekday all go through the calendar, so month ends, year ends, leap days and daylight-saving days work. `DayKey.distantPast` (`0`) is the `effective_from` of one-time schedules.
- **Weeks** start on the calendar's `firstWeekday`, which comes from the user's region (`startOfWeek`, `week`).
- **Minute of day → moment** (`DayKey.date(atMinute:in:)`, `LocalTime`): builds the wall-clock time in the calendar's time zone. A time inside a daylight-saving gap becomes the first moment after the gap (01:30 on 29 Mar 2026 in London → 02:00 BST, D-053). A repeated time uses its first occurrence (01:30 BST on 25 Oct 2026). Minute 1440 is the next day's midnight.
- **Weekday mask** (`Weekdays`): Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64. Mon/Wed/Fri is 21, every day is 127, and one-time tasks store 0.
- **Parts of the day** (`PartSettings`, `DayPart`): defaults Morning 06:00 (360), Noon 12:00 (720), Evening 17:00 (1020), Night 21:00 (1260). Each part ends where the next starts, and Night ends at 1440. `part(containing:)` puts minutes before Morning's start into Morning. `window(of:)` is `[start, end)`.
- **Validation** (`validationError`), checked in this order: every start is within 0–1439 (`outOfRange`), on a 15-minute step (`notOnStep`), later than the previous part's start (`outOfOrder`), and every part lasts at least 30 minutes (`tooShort`), so Night can start no later than 23:30. Morning may start as early as 00:00.
- **Allowed choices** (`allowedStarts(for:)`): the quarter-hour starts a part can take while the other three stay put, keeping every part at least 30 minutes long. Settings (T-10) and the guide (T-28) will use it so invalid times can't be picked.

### Data
None yet. `PartSettings` mirrors the four `*_start` columns of `settings` (SPEC §4.5).

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Calendar/` — `DayKey`, `LocalTime`, `Weekday`, `Weekdays`, `DayPart`, `PartSettings` (with `PartSettingsError`).

### Tests
- `Packages/Core/Tests/CoreTests/Calendar/DayKeyTests.swift`: conversions, day arithmetic across month and year ends, leap days and both London daylight-saving changes, weekdays, week starts by region, gap and overlap moments, midnight, validity, JSON encoding, `LocalTime`.
- `Packages/Core/Tests/CoreTests/Calendar/WeekdaysTests.swift`: the bitmask values (21, 127), calendar weekday numbers, region ordering.
- `Packages/Core/Tests/CoreTests/Calendar/PartSettingsTests.swift`: `partOf` with the defaults, windows, custom times, every validation error, allowed starts.
- `Packages/Core/Tests/CoreTests/Support/TestCalendar.swift`: the fixed Europe/London calendar and Tuesday 6 Oct 2026 reference day (ios.md §13).

### Known gaps
- Timing (fixed time, part, anytime) on tasks arrives with the data model (T-03) and occurrences (T-04).
- Setting the start times in the app comes in Settings (T-10) and the guide (T-28).

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
Status: Partly built (T-03) · Last updated: 2026-10-07 · T-03

### What it does
Everything is stored on the device in one SwiftData store inside the App Group, shared by the app and the widget extension. Device-only state lives in the App Group's `UserDefaults`. There's no account and no server.

### Behavior
- **Tables** (SPEC §4): `tasks`, `schedules`, `completions`, `time_entries` and `settings`, one SwiftData record each. Records are flat, link through `UUID` fields, store enums as the SPEC strings (`one_time`, `progress`, `duration`; `fixed`, `part`, `anytime`; `morning` … `night`; `timer`, `manual`) and day keys as `Int`.
- **IDs** are UUIDs made on the device. The settings row's id is always `00000000-0000-0000-0000-000000000001` (D-056).
- **Writes:** `save` inserts or updates a row by id and sets `updatedAt` to the clock's now on every write. `createdAt` keeps the value it was given.
- **Deletes are soft:** they set `deletedAt` and `updatedAt`. Reads never return rows with `deletedAt` set. Deleting a missing or already deleted row does nothing.
- **Reading order:** tasks by `createdAt` (creation order), schedules by `effectiveFrom`, completions by `day`, time entries by `createdAt`.
- **Bad data:** a row with an unknown enum string, or a schedule whose timing columns don't fit together, is skipped and logged rather than crashing. A time entry with 0 seconds or fewer is rejected with `StorageError.invalidValue`.
- **Settings row:** created with the defaults (SPEC §4.5) the first time the app launches. Later launches keep what's saved. New part start times are checked against the F-02 rules before saving.
- **Device-only state** (SPEC §4.6), one JSON value per key in `UserDefaults(suiteName: "group.com.applab.tempo")`:
  - `deviceState.timer` — the timer: kind (`generic`/`habit`), habit id, start day, accumulated seconds, current segment start (empty while paused).
  - `deviceState.missedSeen` — the popup's seen list: a day and occurrence ids.
  - `deviceState.pendingOpenAction` — for now only "choose a task for a finished timer", with the frozen time.
  - Setting a value to empty removes the key. A value that can't be decoded reads as empty and is logged. The guide-completed flag will use `@AppStorage` (T-28).
- **Sharing with the widgets:** the store file is `Tempo.store` in the App Group container. Every read and write makes a fresh `ModelContext`, so each process sees the other's writes (CLAUDE.md, ios.md §6).
- **If the store can't be opened,** the app shows "Can't open your tasks" / "Something went wrong while opening Tempo's data. Close the app and open it again." (D-057).
- **After every write** through a manager, `RefreshManager.afterChange()` reloads every widget, 0.5 s after the last of a burst of writes. `refreshNow()` skips the wait, for App Intents. Notification rebuilding joins it in T-21.

### Data
All tables in SPEC §4 and the device-only state in §4.6.

### Implementation (iOS)
- Values: `Packages/Core/Sources/Core/Models/` — `TaskValue`, `TaskType`, `ScheduleValue`, `Timing`, `TimingKind`, `CompletionValue`, `TimeEntryValue`, `TimeEntrySource`, `SettingsValue`, `TaskData`, `PendingOpenAction`; `Core/Timer/` — `TimerState`, `TimerKind`, `FinishedTimer`; `Core/Missed/MissedSeenList`.
- Storage: `Shared/Storage/` — `SchemaV1` (records), `MigrationPlan`, `StoreFactory`, `TaskStore` (protocol), `SwiftDataTaskStore`, `DeviceState`, `StorageError`.
- Managers: `Shared/Managers/SettingsManager` (+ `SettingsError`), `RefreshManager`, `WidgetManager` (+ `WidgetReloading`).
- Clock and logging: `Shared/Utilities/Clock/` (`Clock`, `SystemClock`, `FixedClock`; D-054), `Shared/Utilities/Logging/Log`.
- App: `Tempo/App/AppDependencies` creates the managers and makes sure the settings row exists at launch; `Tempo/Views/Root/Components/StoreErrorView`.

### Tests
- `TempoTests/Storage/SwiftDataTaskStoreTests.swift`: create, read, update and soft delete for every table; soft-deleted rows never appear; `updatedAt` on every write; timing round trips; filters and order; settings row.
- `TempoTests/Storage/StoreFactoryTests.swift`: the store lives in the App Group; two containers on one file (as the app and the extension) read each other's writes.
- `TempoTests/Storage/DeviceStateTests.swift`: timer, seen list and pending action survive a new instance (a restart); clearing; unreadable data.
- `TempoTests/Managers/SettingsManagerTests.swift`, `AppDependenciesTests.swift`: defaults created on first launch and kept afterward; invalid part times rejected; widgets refreshed after an update.
- `TempoTests/Managers/RefreshManagerTests.swift`: a burst of changes refreshes once; `refreshNow` is immediate.

### Known gaps
- No sync, by design for v1.
- The widget extension doesn't read the store yet (T-22). Cross-process reads are covered by the two-container test.
