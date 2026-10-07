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

Status: Partly built (T-01) · Last updated: 2026-10-07 · T-09

### What it does
Only the project skeleton exists. No features are live yet. The app opens to a placeholder screen, and the widget gallery offers one placeholder widget.

### Behavior
- **App:** the tab layout from F-09, with placeholder screens.
- **Widget:** one small widget, listed in the gallery as "Tempo" with the description "A placeholder until the real widgets are built." It shows a clock symbol and "Tempo", and never refreshes.
- **iPhone** runs in portrait only. **iPad** supports all four orientations.

### Project and targets
| Item | Value |
|---|---|
| Project / shared scheme | `Tempo.xcodeproj` / `Tempo` (builds the app and extension; tests `TempoTests`) |
| App target | `Tempo`, bundle ID `com.applab.tempo`, display name "Tempo" |
| Widget extension | `TempoWidgets`, bundle ID `com.applab.tempo.widgets`, embedded in the app |
| App tests | `TempoTests`, bundle ID `com.applab.tempo.tests`, hosted in the app |
| UI tests | `TempoUITests`, bundle ID `com.applab.tempo.uitests`, in the `Tempo` scheme; the app runs with `-ui-testing` (in-memory store) (D-064) |
| Logic package | `Packages/Core` (Swift 6 tools, iOS 17 and macOS 14), linked into the app and the extension |
| Deployment target | iOS 17.0, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Swift | App, extension and tests use Swift 5 mode with strict concurrency set to `complete` and `InferSendableFromCaptures` on (D-055). Default actor isolation stays `nonisolated` (D-047). |
| App Group | `group.com.applab.tempo`, in both targets' entitlements |
| URL scheme | `tempo` (app `Info.plist`) |
| Background refresh | `UIBackgroundModes = [fetch]` and `BGTaskSchedulerPermittedIdentifiers = [com.applab.tempo.refresh]`. Nothing is registered yet; that comes in T-21. |
| Signing | Automatic, team `QAUG82L94Y` |

The folder layout matches ios.md §3. Empty folders hold a `.gitkeep`, which is kept out of the bundles (D-048). `Tempo/`, `TempoWidgets/`, `Shared/` and `TempoTests/` are folder-synchronized groups: a file added on disk joins its target automatically. `Shared/` belongs to both the app and the extension.

### Implementation (iOS)
- App: `Tempo/App/TempoApp.swift` (opens the store, or shows the store error screen; see F-26), `Tempo/Views/Root/RootView.swift` (the tabs, F-09)
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
Status: Partly built (T-03, T-04) · Last updated: 2026-10-07 · T-04

### What it does
Tasks are one-time tasks, progress habits or duration habits. The type is set when the task is created; nothing can change it afterward. There's no UI yet.

### Behavior
- Types are stored as `one_time`, `progress` and `duration` (`TaskType`). Progress and duration are habits.
- Titles are trimmed of leading and trailing spaces and newlines, and must then be 1–100 characters (`TaskRules.titleError`: `emptyTitle`, `titleTooLong`).
- One-time tasks have a date; habits have a start day, an optional set length and an optional `ended_on`.
- `TaskManager` has no operation that changes a task's type.

### Data
`tasks.type`, `tasks.title`.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Models/TaskType.swift`, `Core/Schedule/TaskRules.swift`.
- Manager: `Shared/Managers/TaskManager.swift`.

### Tests
- `Packages/Core/Tests/CoreTests/Schedule/TaskRulesTests.swift`, `TempoTests/Managers/TaskManagerTests.swift`.

### Known gaps
- Creating and showing tasks in the app comes with the editor (T-11) and the screens (T-12 onward). Stats show one-time tasks only as a count (T-08).

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
Status: Partly built (T-04, T-11) · Last updated: 2026-10-07 · T-11

### What it does
Habits occur on chosen weekdays between their start and last day, and keep a history of their schedule so edits apply from today onward. The data operations exist in `TaskManager`; there's no UI yet.

### Behavior
- **Occurrence** (SPEC §5.3, `ScheduleEngine`): a one-time task occurs only on its date. A habit occurs on day `d` when `start_day ≤ d`, `d` is on or before its last day (if any), and `d`'s weekday is in the schedule for `d`. Deleted tasks and deleted schedule rows are ignored. Occurrences of one day come in task creation order. An occurrence's id is `<task id in lowercase>_<yyyymmdd>`.
- **Last day** (`TaskValue.lastDay`): the earlier of `start_day + length_days − 1` and `ended_on`; none for an ongoing habit that hasn't been ended. A 30-day habit starting 1 Oct ends on 30 Oct. A habit has ended once its last day is before today (`hasEnded`).
- **Live days** (`ScheduleEngine.isLive`): every day from a habit's start through its last day, scheduled or not (used for logging time, F-05).
- **Schedule for a day:** the row with the greatest `effective_from` that is ≤ that day.
- **Editing timing, weekdays or target** (`TaskManager.updateSchedule`, rules in `ScheduleHistory.edit`, SPEC §4.2):
  - a habit that hasn't started yet: its first row is updated in place;
  - a habit that already has a row starting today: that row is updated, so several edits on one day leave one row;
  - otherwise a new row starts today, and earlier days keep their old schedule;
  - a one-time task: its single row (`effective_from = 0`, weekdays `0`) is updated in place;
  - an edit that changes nothing writes nothing (D-059).
- **Input rules** (`TaskRules`): habits need at least one weekday (`noWeekdays`); duration targets are 5–480 in 5-minute steps (`invalidTarget`); progress habits and one-time tasks have no target; set lengths are 1–365 (`invalidLength`); fixed times are minutes 0–1435 on 5-minute steps (`invalidFixedTime`); a habit can't start before today, and a one-time date can't be before today (`dayInPast`).
- **Creating** (`createOneTime`, `createHabit`): the task and its first schedule row are written together. A habit's first row starts on its start day.
- **Title** (`rename`): trimmed and validated; applies everywhere, since history reads the same row.
- **Length** (`setLength`): moves the last day. If the new last day would be before today, the habit is ended as with End habit instead, and its length is left as it was, so the days it already had stay in its history (D-058).
- **Start day** (`setStartDay`): only while the start is still in the future, and never to a day before today (`notAllowed`, `dayInPast`). The first schedule row moves with it.
- **End habit** (`endHabit`): `ended_on` becomes yesterday, or today if today already has a completion or a time entry. A habit that has already ended is left alone.
- **Start again** (`startAgain`): a new habit with the same title, type, latest schedule (timing, weekdays, target) and length, starting today. The ended habit is unchanged.
- **Delete with history** (`deleteWithHistory`) and **delete a one-time task** (`deleteOneTime`): soft-delete the task and all its schedules, completions and time entries in one write.
- Every write refreshes the widgets through `RefreshManager.afterChange()`.

### Data
`tasks` (`start_day`, `length_days`, `ended_on`), `schedules` (all columns). Reads `completions` and `time_entries` for End habit.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Schedule/` — `ScheduleEngine`, `ScheduleHistory`, `TaskRules` (+ `TaskRuleError`); `Core/Models/Occurrence.swift`, `TaskValue.lastDay`.
- Manager: `Shared/Managers/TaskManager.swift` (+ `TaskError`). Multi-row changes use the store's atomic `write(_:)` with `StoreWrite` values (`Shared/Storage/StoreWrite.swift`).

### Tests
- `Packages/Core/Tests/CoreTests/Schedule/ScheduleEngineTests.swift`: every T-04 occurrence case, last days, schedule lookup, deleted rows, creation order, windows.
- `Packages/Core/Tests/CoreTests/Schedule/ScheduleHistoryTests.swift`: new row, same-day update, not-started update, one-time update, no-op.
- `TempoTests/Managers/TaskManagerTests.swift`: creation and validation, the Wednesday weekday change, two edits on one day, not-started edits, rename, length, start day, End habit, Start again, deletes.
- `TempoTests/Storage/SwiftDataTaskStoreTests.swift`: batch writes are all-or-nothing.

### Known gaps
- The weekly goal (T-06), results in History (T-14) and the editor UI with its note (T-11).
- The editor (F-15) is the UI for these operations; Start again starts today even when the habit's part has ended (D-070).

## F-04 · Daily cycle and status
Status: Partly built (T-05) · Last updated: 2026-10-07 · T-05

### What it does
Every occurrence's status is computed from the clock (SPEC §5.4), never stored. `TaskManager` checks what each day allows before every write. There's no UI yet.

### Behavior
- **Statuses** (`Status`): `upcoming`, `open`, `done`, `short`, `missed`. Done, Short and Missed are final; Short and Missed count as missed.
- **Algorithm** (`StatusRules.status`, exactly SPEC §5.4):
  1. One-time or progress with a live completion for (task, day) → Done. Duration with the day's minutes ≥ that day's schedule target → Done, at any time of day, even before its part starts.
  2. A future day → Upcoming.
  3. Today: before the window → Upcoming; inside it → Open.
  4. Otherwise (window over, or a past day): a duration habit with at least 1 whole minute → Short; anything else → Missed.
- **Windows:** a part's `[start, end)`; a fixed time uses the window of the part that contains it (so a 12:30 task is Open 12:00–17:00 and Missed at 17:00, and a 05:00 task waits for Morning at 06:00); Anytime is the whole day, so it's Missed at midnight.
- **Minutes** are whole minutes rounded down from the summed seconds, so 59 seconds alone don't make a task Short.
- Statuses use the current part times, so changing a start time moves today's statuses at once.
- **What each day allows** (`Editability`):
  - Complete or undo: one-time tasks today or later; progress habits only today, and only on scheduled days. Duration habits are never checked off.
  - Log time: duration habits only today, and only between their start and last day (scheduled or not).
  - Delete a time entry: only today's.
  - Move: one-time tasks today or later that aren't done (D-060).
  - Edit or delete a one-time task: only while its date is today or later.
  - Edit a habit's schedule or length: only until it ends. Titles can always change.
- **Complete** (`TaskManager.complete`) writes one completion row; doing it again changes nothing. **Undo** (`undoCompletion`) soft-deletes every row for the (task, day) pair, so duplicates are harmless. **Toggle** (`toggleCompletion`) does whichever applies (for the widget checkbox, T-24).
- **Move to tomorrow / Move to next day** (`moveToNextDay`, rule in `Editability.movePlan`): a task that isn't missed changes its date by one day. A task Missed today stays on today as missed, and a copy with the same title and timing is created for tomorrow.
- A refused change throws `TaskError.notAllowed` and writes nothing.

### Data
Reads `completions` and `time_entries`; writes `completions` and `tasks.date`. Uses the part times from `settings` (defaults if the row is missing).

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Status/` — `StatusRules`, `Editability`, `MovePlan`; `Core/Models/Status`, `ActivityLog` (completions and seconds by task and day), `Snapshot` (data + settings + rules in one value).
- Manager: `Shared/Managers/TaskManager.swift` — `snapshot()`, `complete`, `undoCompletion`, `toggleCompletion`, `moveToNextDay`, and Editability checks in every edit.

### Tests
- `Packages/Core/Tests/CoreTests/Status/StatusRulesTests.swift`: the Noon task through the day, the 12:30 task, Anytime and Night at midnight, early fixed times, Short/Missed/Done for duration habits, rounding, past and future days, changed part times, undone completions.
- `Packages/Core/Tests/CoreTests/Status/EditabilityTests.swift`: today, past and future days, logging on unscheduled days, move plans, frozen ended habits.
- `TempoTests/Managers/TaskCompletionTests.swift`: the same rules through `TaskManager` and the store, including both kinds of Move to tomorrow.

### Known gaps
- Screens that show statuses and offer these actions come in T-12 onward. The timer's exception for past days arrives with T-19.

## F-05 · Time tracking
Status: Partly built (T-06, T-12) · Last updated: 2026-10-07 · T-12

### What it does
Duration habits collect time entries. The math for minutes, weekly goals and totals is in `Core`, and `TaskManager` can log time by hand and delete today's entries. There's no UI yet.

### Behavior
- **Minutes** for a habit on a day: the sum of that day's live entries' seconds, divided by 60 and rounded down (3,599 s → 59 min). There's no upper limit.
- **Scheduled days** in a range: days between the start and last day whose weekday is in that day's schedule.
- **Goal** over a range (`DurationMath.goal`): the sum of each scheduled day's own target, so a target changed mid-week adds up day by day (30 + 45 + 45).
- **Total** over a range (`total`): the minutes of every live day in the range, scheduled or not. Minutes on an unscheduled day count toward totals but don't make the day scheduled.
- **Weekly progress** (`weeklyProgress`): goal and total for the week containing a day, starting on the region's first weekday, counting only days between the start and last day. The goal is met when the total reaches it. The SPEC §5.5 example gives a goal of 90 and a total of 115.
- **Log time** (`TaskManager.logTime`): a manual entry on today, 5–480 minutes in 5-minute steps (`invalidLogTime`). Only duration habits (`wrongType`), and only when today is between the habit's start and last day (`notAllowed`), whether or not today is scheduled. Entries can't be added to future or past days.
- **Deleting an entry** (`deleteTimeEntry`): only entries from today; past entries are read-only (`notAllowed`).

### Data
`time_entries` (`source = manual` for Log time).

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Duration/` — `DurationMath`, `GoalProgress`; `TaskRules.logTimeError`.
- Manager: `Shared/Managers/TaskManager.swift` — `logTime`, `deleteTimeEntry`.
- Views: `Tempo/Views/LogTime/LogTimeView`, `LogTimeViewModel` (T-12).

### Tests
- `Packages/Core/Tests/CoreTests/Duration/DurationMathTests.swift`: rounding, summing, the §5.5 example, a mid-week target change, mid-week weekday change, start and last days, unscheduled days, region week start, Log time steps.
- `TempoTests/Managers/TimeLoggingTests.swift`: Log time on today and unscheduled days, refused on future and ended habits, steps, type, deleting today's but not past entries.
- `TempoTests/ViewModels/LogTimeViewModelTests.swift`: the starting value, adding to today, the choices, refusing outside the habit's days.

- **Log time sheet** (T-12): opened from a duration row's "Log time" swipe (later also from Missed and Habit detail). It shows the habit's title, "Today" with "12 of 30 min", and a wheel of 5–480 minutes in 5-minute steps, starting at the minutes left to reach today's target rounded up to 5 (30 once the target is reached) (D-073). "Add" saves to today and closes; "Cancel" closes. If time can't be logged today, Add is disabled with "Time can only be logged today, between the habit's start and last day."

### Known gaps
- Today's entries in Habit detail (T-15), and the timer's entries (T-19).

## F-06 · Timer
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-06._

## F-07 · Notifications
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-07._

## F-08 · Missed tasks
Status: Partly built (T-03, T-07) · Last updated: 2026-10-07 · T-07

### What it does
The missed queries (SPEC §5.8) exist in `Core`, with the Earlier section's filters and sort orders. The seen list is stored on the device (T-03). There's no Missed tab or popup yet.

### Behavior
- **Missed today** (`MissedQueries.missedToday`): today's occurrences whose status is Missed or Short, in day order (`DayOrder`: Morning → Night → Anytime; fixed times first in time order, then part-of-day tasks in creation order).
- **Missed earlier** (`missedEarlier`): every Missed or Short occurrence before today. Ended habits are included; deleted tasks never appear. Days are sorted newest first (default) or oldest first; within a day, day order.
- **Each item** (`MissedItem`) carries its occurrence, status, and for duration habits the minutes logged and that day's target ("20 of 30 min").
- **Filters** (`MissedFilter`):
  - Date range: All (default), This week (region's first weekday through six days later), This month, or a custom range (inclusive, either order).
  - Type: any combination of one-time, progress and duration; all by default.
  - Part of the day: any combination of Morning, Noon, Evening, Night and Anytime; fixed-time tasks count under their part. All by default.
  - A specific task.
  - `isActive` is true when any filter differs from its default; sorting doesn't count. `cleared` resets the filters and keeps the sort order.
- **Unseen** (`unseen`): missed today minus the seen list. A seen list from another day counts as empty.

### Data
Reads everything through a `Snapshot`; the seen list is `deviceState.missedSeen` (F-26).

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Missed/` — `MissedQueries`, `MissedFilter`, `MissedDateRange`, `MissedPartFilter`, `MissedSort`, `MissedItem`, `MissedSeenList`; `Core/Schedule/DayOrder`.

### Tests
- `Packages/Core/Tests/CoreTests/Missed/MissedQueriesTests.swift`: Short in missed today, both sort orders, every filter alone and combined, clearing, ended and deleted tasks, past Short days, unseen with current and stale lists, date bounds.
- `Packages/Core/Tests/CoreTests/Schedule/DayOrderTests.swift`.

### Known gaps
- The Missed tab and its badge (T-16) and the popup (T-17).

## F-09 · Navigation and app structure
Status: Built (T-09) · Last updated: 2026-10-07 · T-09

### What it does
The app opens to four tabs. Settings, History, the editor, the timer screen and the task picker open from buttons and from links. Some screens are still placeholders that later tasks fill in.

### Behavior
- **Tabs** (left to right): Today (`sun.max`), Tasks (`checklist`), Missed (`exclamationmark.circle`), Stats (`chart.bar`). The app starts on Today.
- **Missed badge:** the number of today's Missed and Short tasks; hidden at 0. It's recounted on launch, after every change, when the app becomes active, and every minute (statuses change at part boundaries).
- **Settings** opens from a gear button (accessibility label "Settings") at the top right of Today, pushed onto Today's navigation stack. **History** opens from a clock button ("History") on Tasks, pushed onto Tasks' stack (D-063).
- **Floating + button** ("Add task"): bottom right of Today and Tasks only. Today's opens the editor preset to the selected day (F-10); Tasks' presets a progress habit (the segment comes with T-13). Scrolling content on those screens keeps an 88-point bottom margin, so the last row is never under the button.
- **Timer bar slot:** every tab's root has a bottom safe-area inset for the timer bar, just above the tab bar. It takes no space until a timer exists (T-20).
- **Presented over the tabs** as sheets: the editor, the timer screen and the task picker (D-063).
- **Links** (`tempo://`, parsed by `DeepLink`):
  - `today[?day=yyyymmdd][&part=…][&task=<uuid>]` → the Today tab; the day, part and task are kept in `NavigationRouter.todayFocus` for the Today screen (T-12).
  - `new[?day=yyyymmdd][&type=one_time|progress|duration]` → the editor with those presets.
  - `missed` → the Missed tab.
  - `timer` → the timer screen.
  - Anything else, or a different scheme, → Today. Unknown or malformed parameters are ignored.
  - Opening a link first closes whatever was presented (a sheet, Settings or History).
- **Pending open action:** when the app becomes active, a stored "choose a task for the finished timer" action opens the task picker and is cleared.
- **Opened from a link:** a link or pending action marks the activation as not normal (`openedFromLinkThisActivation`), for the missed popup (T-17). It resets when the app goes to the background.
- When the app becomes active, open screens reload, in case a widget changed something.
- **Placeholders** until their tasks: Missed (T-16), Stats (T-18), the timer screen (T-20, "Timer" with Close) and the task picker (T-20, "Choose a task" with Close). Each placeholder says "This screen is being built."

### Data
Reads today's missed count; reads and clears `deviceState.pendingOpenAction`.

### Implementation (iOS)
- App: `Tempo/App/` — `TempoApp`, `AppDependencies` (now `@Observable`, put in the environment), `NavigationRouter`, `AppTab`, `TodayFocus`, `EditorRequest`, `TaskPickerRequest`, `LaunchOptions` (UI-test launch arguments).
- Views: `Tempo/Views/Root/RootView`, `RootViewModel`; placeholder views in `Views/Today`, `Tasks`, `Missed`, `Stats`, `Settings`, `History`, `TaskEditor`, `TimerScreen`, `TaskPicker`.
- Components: `Tempo/Components/FloatingAddButton/FloatingAddButton` (with the `floatingAddButton(action:)` modifier), `Tempo/Components/TimerBar/TimerBar` (empty slot).
- Links: `Shared/DeepLink/DeepLink.swift`.
- Managers: `Shared/Managers/MissedManager` (badge count); `RefreshManager.revision`, which screens watch to reload.

### Tests
- `TempoTests/Navigation/DeepLinkTests.swift`: parsing every destination and parameter, unknown and malformed links, URLs that parse back.
- `TempoTests/Navigation/NavigationRouterTests.swift`: each link's effect, the pending action, closing presented screens, the link flag.
- `TempoTests/Managers/MissedManagerTests.swift`: the badge count includes Short.
- `TempoUITests/NavigationUITests.swift`: the four tabs, gear → Settings, clock → History, + on Today and Tasks only, every link destination opened in the running app.

### Known gaps
- The screens behind the tabs are placeholders until their tasks.
- The missed popup (T-17) and the timer bar's content (T-20).

## F-10 · Today screen
Status: Partly built (T-12) · Last updated: 2026-10-07 · T-12

### What it does
The Today tab shows one day at a time: a day strip, then Morning, Noon, Evening, Night and Anytime, with the actions F-04 allows. It updates every minute while open.

### Behavior
- **Title:** "Today", "Tomorrow", "Yesterday", or a short date in the user's format ("Thu 8 Oct"), as a large navigation title. The gear (Settings) is at the top right. A "Today" button appears at the top left whenever another day is selected.
- **Day strip:** the seven days of the selected day's week, starting on the region's first weekday; each shows its weekday initial and number. Today's number is in the accent color; the selected day is circled (accent for today, black/white otherwise). A grey dot means the day has tasks; a red dot means today or a past day has Missed or Short tasks (D-076). Tapping a day selects it. Swiping the strip left or right moves the selection by a week. VoiceOver reads each day's full date and "No tasks", "Has tasks" or "Has missed tasks", and offers "Next week" and "Previous week" actions.
- **Sections** in order: Morning, Noon, Evening, Night, Anytime (`DayPlan`). Within a part, fixed-time tasks come first in time order, then part-of-day tasks in creation order.
  - On today, an ended part with tasks folds into one tappable line, "Morning · 2 done · 1 missed" (Short counts as missed), with a chevron; tapping shows or hides its tasks. Expanded parts fold again when another day is selected (D-075).
  - The part in progress has its name in bold accent color and "ends in 1h 20m" on the right, recalculated every minute.
  - Other parts, and every part on other days, show their name as a plain header.
  - A part with no tasks shows small grey text: "Nothing this morning", "Nothing at noon", "Nothing this evening", "Nothing tonight" on today; "Nothing in the morning", "Nothing at noon", "Nothing in the evening", "Nothing at night" on other days; "No anytime tasks" for Anytime (D-074).
- **Rows:**
  - One-time tasks and progress habits: a checkbox (accessibility "Mark done"/"Mark not done" with the title), the title (struck through and grey when done), "Habit" with a repeat icon for progress habits, the fixed time on the right if there is one, and a red "Missed" label when missed. The checkbox is disabled where F-04 doesn't allow completing.
  - Duration habits: a progress ring, the title, "10 of 30 min", the fixed time if any, and "Done", "Short" or "Missed" with an icon once final. Time can still be added after Done.
  - Statuses always come with text and an icon.
- **Tapping a row:** a one-time task opens the editor (read-only for past days); a habit opens Habit detail.
- **Swipe actions**, only where F-04 allows (D-077):
  - From the left: "Done"/"Undo" (one-time and progress, today; one-time on future days), "Log time" (duration habits, today).
  - From the right: "Delete", "Edit" (today and later), "Move to tomorrow" on today or "Move to next day" on a future day (one-time tasks that aren't done).
  - Past days have no swipe actions.
- **Delete:** a one-time task asks "Delete this task?" ("This can't be undone."). A habit asks "End or delete this habit?" with "End habit" and "Delete with history" ("End habit keeps its history and stats. Delete with history removes them for good.").
- **Floating +:** opens the editor preset to the selected day (today when a past day is selected).
- **Links:** `tempo://today?day=…&part=…&task=…` selects the day, unfolds the part (or the task's part) and scrolls to the part or task.
- **Empty states** (F-24): today with no tasks → "No tasks today" with "Add a task"; a future day → "Nothing planned for Thu 8 Oct" with "Add a task" preset to that day; a past day → "Nothing was planned for Mon 5 Oct". The day strip stays visible.
- If an action fails, an alert "Couldn't change the task" explains why.
- Reloads after every change (`RefreshManager.revision`) and when the app becomes active.
- **Log time sheet** (F-05): see F-05.

### Data
Reads everything through a `Snapshot`; writes completions, dates (move), copies, time entries and deletes through `TaskManager`.

### Implementation (iOS)
- Views: `Tempo/Views/Today/TodayView`, `TodayViewModel`; `Components/` — `DayStrip`, `DayStripDay`, `PartHeader`, `CollapsedPartRow`, `TaskRow`, `DurationRow`, `StatusLabel`.
- Rules: `Packages/Core/Sources/Core/Schedule/DayPlan` (+ `DaySection`, `DayItem`, `DaySectionPhase`).
- Utilities: `Shared/Utilities/Formatters/DayTitleFormatter`, `DurationFormatter`.
- App: `Tempo/App/Route` (Habit detail), `LogTimeRequest`; `NavigationRouter.logTime`.
- Placeholder: `Tempo/Views/HabitDetail/HabitDetailView` (T-15).
- `Tempo/App/SampleData` fills previews and UI tests (`-ui-testing-sample`) with a realistic week.

### Tests
- `Packages/Core/Tests/CoreTests/Schedule/DayPlanTests.swift`: section order, items per part, phases, before Morning, other days, counts and progress.
- `TempoTests/ViewModels/TodayViewModelTests.swift`: spec order, statuses at boundaries, collapsing, dots and week moves, titles, read-only past days, F-04 on future days, today's actions including Move to tomorrow, deletes, link focus.
- `TempoUITests/TodayUITests.swift`: checkbox complete/undo, Log time from a swipe, Move to tomorrow from a swipe, swiping the strip by a week and the Today button, unfolding an ended part, disabled checkboxes on past days.

### Known gaps
- ▶ on duration rows and hiding it while a timer exists (T-20).
- The missed popup (T-17).
- Haptics on completing and switching days (T-31).

## F-11 · Tasks tab
Status: Built (T-13) · Last updated: 2026-10-07 · T-13

### What it does
Two lists behind a segmented control: active habits with their progress, and upcoming one-time tasks.

### Behavior
- **Segment:** "Habits" (default) or "One-time". The last choice is stored with `@AppStorage("tasksSegment")` and survives a restart.
- **Habits:** every habit that hasn't ended, in creation order, including habits that haven't started yet. Each row has a type icon (progress `checkmark.circle`, duration `timer`), the title, a schedule summary and a progress line:
  - schedule: "Every day", "Weekdays", "Weekends", or short weekday names in the region's order ("Mon, Wed, Fri"), then " · " and the timing ("Evening", "12:30", "Anytime"). It uses the latest schedule, which applies from today.
  - progress habits: "4 of 5 this week" (done scheduled days of this week out of its scheduled days, within the habit's start and last day), or "Day 12 of 30" when it has a set length;
  - duration habits: "2h 10m of 3h 30m this week" (weekly total against the weekly goal, SPEC §5.5);
  - a habit that hasn't started: "Starts Thu 8 Oct" (D-078).
  - Tapping a row opens Habit detail.
- **One-time:** every one-time task dated today or later that isn't done and isn't missed, grouped under "Today", "Tomorrow" or a short date, in day order within a date. Each row shows the title and its timing. Tapping opens the editor. Today's missed tasks are in the Missed tab instead.
- **Floating +:** opens the editor with a progress habit preset on Habits (it can still be changed), or a one-time task on One-time.
- **Clock button:** opens History.
- **Empty states** (F-24): "No habits yet" with "Add a habit"; "No upcoming tasks" with "Add a task".

### Data
Reads everything through a `Snapshot`.

### Implementation (iOS)
- Views: `Tempo/Views/Tasks/TasksView`, `TasksViewModel`, `TasksSegment`, `HabitSummary`, `OneTimeGroup`; `Components/HabitRow`, `OneTimeRow`.
- Rules: `Packages/Core/Sources/Core/Stats/HabitProgress` (week counts, day of length, not started); `DurationMath.weeklyProgress`.
- Utilities: `Shared/Utilities/Formatters/ScheduleFormatter`.

### Tests
- `Packages/Core/Tests/CoreTests/Stats/HabitProgressTests.swift`.
- `TempoTests/ViewModels/TasksViewModelTests.swift`: active habits and their progress lines, set lengths, upcoming one-time tasks grouped by date without done or missed ones, empty lists, weekday summaries.
- `TempoUITests/TasksUITests.swift`: the segment survives a restart; + presets the type from the segment, with both empty states.

### Known gaps
- None for F-11. Habit detail itself comes in T-15.

## F-12 · History
Status: Built (T-14) · Last updated: 2026-10-07 · T-14

### What it does
History, pushed from the clock on Tasks, lists completed one-time tasks and ended habits, with a search field.

### Behavior
- **Segment:** "One-time" (default) or "Habits".
- **One-time:** every one-time task with a completion, grouped by the day it was actually completed (the completion's time), newest day first and newest first within a day, under "Today", "Yesterday" or a short date (D-079). A task completed early for a later date shows under the day it was done. Rows show a filled checkmark and the title struck through. The checkmark ("Mark not done") works only for tasks completed today whose date is today or later; older ones are read-only.
- **Habits:** every habit whose last day is before today (its set length finished, or it was ended by hand), most recently ended first. Each row shows its type icon, title, result, "Ended Sat 26 Sep", and a "Start again" button:
  - progress habits: "Done 27 of 30 days" (done days out of counted scheduled days over the habit's life);
  - duration habits: "On target 18 of 20 days · 14h 20m total".
  - Start again creates the same habit starting today (F-03) and confirms with "Started again" / "“Gym” starts again today. You'll find it in Tasks." The ended habit stays in History.
  - Tapping a row opens Habit detail.
- **Search:** filters both segments by title, ignoring case and diacritics.
- **Empty states** (F-24): "Nothing completed yet", "Finished habits will appear here", and "No matches" when a search finds nothing.

### Data
Reads completions, tasks and time entries; writes completions (undo) and new habits (Start again).

### Implementation (iOS)
- Views: `Tempo/Views/History/HistoryView`, `HistoryViewModel`, `HistorySegment`, `CompletedTask`, `CompletedGroup`, `EndedHabit`; `Components/CompletedTaskRow`, `EndedHabitRow`.
- Rules: `StatsCalculator.rate(of:from:through:)`, `DurationMath.total`.

### Tests
- `TempoTests/ViewModels/HistoryViewModelTests.swift`: grouping by completion day, newest first; undo only today; results for both habit types and their order; Start again; search; empty segments.
- `TempoUITests/HistoryUITests.swift`: empty states; an ended habit's result and Start again; a task completed on Today appears, search with no matches, and Mark not done.

### Known gaps
- None for F-12.

## F-13 · Habit detail
Status: Partly built (T-15) · Last updated: 2026-10-07 · T-15

### What it does
Pushed from a habit row in Today, Tasks or History, it shows one habit's schedule, this week, a month calendar, stats, streak, today's time entries and recent missed days.

### Behavior
- **Title bar:** the habit's title, and "Edit" (opens the editor) on the right.
- **Header:** the type with its icon, the title, the schedule summary ("Every day · Evening"), and for duration habits the target ("30 min a day"), then the length: "Day 12 of 30", "Ongoing", "Starts Thu 8 Oct" or "Ended Sat 26 Sep".
- **Buttons:** "Log time" (duration habits, when time can be logged today; opens the Log time sheet), and "End habit" (with the confirmation "End this habit?" / "It moves to History with its stats, and you can start it again later.") for an active habit, or "Start again" for an ended one (confirmed with "Started again").
- **This week:** seven days in the region's order, each with an icon and color: done (filled check), short (half circle), missed (filled x), upcoming (empty circle, including today while open), not scheduled (dash). VoiceOver reads the weekday and the result.
- **Month calendar:** the month's grid starting on the region's first weekday. Done days are green, missed red, short pale orange, upcoming outlined; today has an accent ring. Arrows move between months, from the habit's start month up to the current month. A legend (Done, Short, Missed, Upcoming) with icons sits under it. Each day reads its date and result to VoiceOver.
- **Stats:** "This week", "This month" and "This year", each with the completion rate ("—" with no counted days, SPEC §5.7). Duration habits add the time: this week "1h 5m of 3h 30m" (against the weekly goal), the month and year "2h 20m total".
- **Streak:** "Current" and "Best", in days (§5.7).
- **Today's time** (duration habits): each of today's entries with its source ("Timer" or "Logged by hand") and minutes; swipe to delete. "No time logged today" when empty. Past entries never appear here, so they can't be deleted.
- **Recent missed days:** up to 10 Missed or Short days, newest first, including today's (D-080). Short days show "20 of 30 min"; missed days show a red "Missed" with an icon. "See all" switches to the Missed tab with Earlier filtered to this habit (the filter is applied by the Missed tab, T-16).
- **No data yet** (F-24): until the habit has a counted day or any time logged, the week, calendar, stats, streak and missed sections are replaced by "No data yet. Check back after its first day."
- If the habit was deleted, the screen says "This habit no longer exists".

### Data
Reads everything through a `Snapshot`; deletes time entries, ends habits and starts them again through `TaskManager`.

### Implementation (iOS)
- Views: `Tempo/Views/HabitDetail/HabitDetailView`, `HabitDetailViewModel`, `DayResult`, `RangeStat`; `Components/WeekDots`, `MonthCalendar`, `DayResultMark`.
- Rules: `StatsCalculator` (`statuses`, `rate`, `streak`), `DurationMath`, `MissedQueries`, `HabitProgress`.
- App: `NavigationRouter.showMissed(for:)` and `missedTaskFilter`.

### Tests
- `TempoTests/ViewModels/HabitDetailViewModelTests.swift`: week dots, the month calendar and its limits, stats and streak, recent missed days (order and the limit of 10), duration time and weekly goal, deleting today's but not past entries, header texts and buttons, no data yet, "See all".
- `TempoUITests/HabitDetailUITests.swift`: opening from Today with its sections, End habit confirming first, "See all" opening Missed.

### Known gaps
- ▶ for duration habits, hidden while a timer exists (T-20).
- Missed tab filtering for "See all" (T-16).

## F-14 · Stats
Status: Partly built (T-08) · Last updated: 2026-10-07 · T-08

### What it does
The stats formulas (SPEC §5.7) and the data for every Stats card exist in `Core` (`StatsCalculator.stats(for:)` → `StatsSnapshot`). The screen comes in T-18.

### Behavior
- **Ranges** (`StatsRange`): a week (region's first weekday), a calendar month or a calendar year. `previous`/`next` step by one range. The screen may go forward only while the next range has started (`canGoForward`), and back only while the previous range ends on or after the day the first live task was created (`canGoBack`, `firstDay`).
- **Counting:** ranges count up to and including today. Past occurrences always count; today's count only once Done, Missed or Short. Future days never count.
- **Completion rate** (`CompletionRate`): done ÷ counted, shown as a whole percent rounded half up (23 of 28 → 82%). With no counted days it's `nil`, shown as "—" (D-062).
- **Change from previous:** this range's percent minus the previous range's, in points, using the rounded percents. `nil` (hidden) when either range has no counted days.
- **One-time completed:** one-time tasks whose date is in the range, up to today, with a completion. A task completed early for a later date counts once its date arrives.
- **Total time:** minutes across every duration habit and live day in the range.
- **Completion chart data:** one `DayRate` per day of the range; for a year, also one `MonthRate` per month.
- **Time per duration habit** (`HabitTime`): minutes in the range against the sum of its targets over every scheduled day of the range, including days still to come.
- **Parts of the day** (`PartRate`): done ÷ counted for Morning, Noon, Evening, Night and Anytime over every type of occurrence with a final status; fixed times count in their part. **Most missed** is the lowest rate among those with at least 3 counted, the earlier part winning a tie; none if no part has 3.
- **Streaks** (`Streak`): per habit, the run of consecutive done scheduled days counting back from the most recent counted day (unscheduled days are skipped; an Upcoming or Open today doesn't break it, and a Done today extends it). Best is the longest run ever. Sorted by current streak, highest first, then creation order.
- **Habits list** (`HabitRate`): each habit live on at least one day of the range, with its rate. Ended habits appear for ranges they were live in. No habits → `hasHabits` is false (empty state, F-24).
- **Per-habit helpers** for Habit detail: `rate(of:from:through:)`, `statuses(of:from:through:)` (status per scheduled day; unscheduled days are absent), `streak(of:)`.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Stats/` — `StatsCalculator`, `StatsSnapshot` (+ `DayRate`, `MonthRate`, `HabitTime`, `PartRate`, `HabitStreak`, `HabitRate`), `StatsRange` (+ `StatsRangeKind`), `CompletionRate`, `Streak`.

### Tests
- `Packages/Core/Tests/CoreTests/Stats/StatsCalculatorTests.swift`: 23 of 28 → 82%, rounding, today's evening habit at 13:00, future days, change hidden and shown, duration goals with future days, part rates and Most missed with the minimum of 3, final statuses only, streaks across unscheduled days and an Open today, best runs, streak order, no habits → "—", one-time counts, chart sizes, habits live in a range, range navigation, first day, week statuses.

### Known gaps
- The Stats screen (T-18) and Habit detail (T-15).

## F-15 · Task editor
Status: Built (T-11) · Last updated: 2026-10-07 · T-11

### What it does
A sheet for creating a task or editing one. Presets for the day and type come from where it was opened.

### Behavior
- **Title bar:** "New task", "Edit task", or "Task" when read-only. Cancel (Close when read-only) on the left; Save on the right, disabled until the task is valid.
- **Type:** a segmented One-time / Progress / Duration picker for new tasks, with a one-line explanation under it ("Done once, on one day.", "A habit you check off on the days it repeats.", "A habit measured in minutes against a daily target."). When editing it's shown read-only with "The type can't be changed after a task is created."
- **Title:** a text field. "Add a title" appears in red under it once it has been edited and is empty (D-068).
- **When:** Fixed time / Part of the day / Anytime.
  - Fixed time: a time picker in 5-minute steps.
  - Part of the day: Morning, Noon, Evening and Night as rows with a checkmark on the chosen one.
  - Anytime: "Anytime tasks belong to no part of the day and stay open until midnight."
  - On today (the date of a one-time task, or a habit's start day, or today for edits to a habit that has started), parts that have ended are grey with "Already over" and can't be picked, and the time picker starts at the first part that hasn't ended. A timing the task already had can stay, so a missed task can still be renamed (D-069). If the chosen timing is over, Save is disabled and the footer says "That part of the day is already over. Pick a later time."
- **One-time:** "Date", from today onward; defaults to the preset day or today.
- **Habits** ("Schedule" section): "Repeat on" with seven weekday toggles in the region's order, all on by default ("Pick at least one day" in red when none are on); "Starts", from today onward, read-only once the habit has started; "Set length" toggle with a day stepper (1–365, 30 when switched on). Footer: "Ongoing until you end it." without a length, or, when editing a habit, "Changes apply from today. Earlier days keep their old schedule."
- **Duration:** "Daily target", a stepper from 5 to 480 minutes in 5-minute steps, 30 by default.
- **Defaults for a new task:** the part of the day in progress (Morning on other days or before Morning starts), and for fixed time the next 5-minute step after now (09:00 on other days) (D-068).
- **Saving:**
  - New one-time task → `createOneTime`; new habit → `createHabit` (task and first schedule row together).
  - Editing a one-time task → `updateOneTime` (title, date and timing in one write).
  - Editing a habit → rename, then the start day if it moved (only while in the future; the first schedule row moves too), then the schedule (`updateSchedule`, rows per SPEC §4.2) and the length.
  - If saving fails (for example a part ended while the editor was open), an alert "Couldn't save" explains why.
- **Edit mode** adds, after confirmation dialogs:
  - one-time tasks: "Delete task" ("Delete this task?" / "This can't be undone.");
  - habits: "End habit" ("End this habit?" / "It moves to History with its stats, and you can start it again later.") and "Delete with history" ("Delete this habit and its history?" / "All of its history and stats will be deleted. This can't be undone. End the habit instead to keep them."), whose dialog also offers End habit (D-072).
- **Read-only:** a one-time task dated before today opens read-only, with no Save or Delete. An ended habit keeps its title editable but its schedule, length and End habit are unavailable; Delete with history stays (D-071).
- **TaskManager rules added for the editor** (also enforced outside it): a new task can't be put in a part of today that has ended (`partAlreadyOver`, D-035); neither can a schedule edit that applies today (D-069). Start again is the exception: it starts today even if the habit's part has ended (D-070).

### Data
Writes `tasks` and `schedules` (and soft deletes everything of a deleted task).

### Implementation (iOS)
- Views: `Tempo/Views/TaskEditor/TaskEditorView`, `TaskEditorViewModel`.
- Components: `Tempo/Components/WeekdayPicker/WeekdayPicker`, `MinuteIntervalPicker` (5-minute steps).
- Manager: `TaskManager.updateOneTime`, `parts()`, `isOver(_:on:)`, and the D-035 checks in `createOneTime`, `createHabit` and `updateSchedule`.
- Rules: `TaskRules.isOver`, `TaskRules.earliestFixedMinute`, `TaskRuleError.partAlreadyOver`.
- Utilities: `Shared/Utilities/Extensions/TaskType+Title` (names, explanations, icons), `Weekday+Title`.

### Tests
- `TempoTests/ViewModels/TaskEditorViewModelTests.swift`: every type with every timing, presets, defaults, the title and weekday messages, past days, ended parts and fixed times, read-only type when editing, editing one-time tasks and habits (schedule rows and the note), future start days, read-only past tasks, delete, End habit and Delete with history.
- `Packages/Core/Tests/CoreTests/Schedule/TaskRulesTests.swift` (`TaskRulesTimingTests`): when a timing is over, the earliest fixed time.
- `TempoUITests/TaskEditorUITests.swift`: creating a task, the title message and habit fields, "Already over" parts.

### Known gaps
- Opening the editor for an existing task comes from Today's rows (T-12), Tasks (T-13) and Habit detail (T-15).
- Ending or deleting a habit whose timer is running asks first and discards the timer (T-19/T-20).

## F-16 · Settings
Status: Partly built (T-10) · Last updated: 2026-10-07 · T-10

### What it does
Settings is pushed from the gear on Today. Every change is saved as soon as it's made and keeps its value after a restart.

### Behavior
- **Parts of the day:** Morning, Noon, Evening and Night, each with a compact time picker in 15-minute steps (`MinuteIntervalPicker`). Each picker only offers start times that keep the parts in order and at least 30 minutes long (`PartSettings.allowedStarts`), so invalid times can't be chosen. Footer: "Each part ends when the next one starts, and Night ends at midnight. Every part lasts at least 30 minutes." If Night moves past the recap time, the recap moves to the first allowed time (D-066).
- **Reminders**, all on by default:
  - "Part starts" (on/off).
  - "Ending soon" (on/off), and when on, "Before the part ends": 15, 30 (default), 45 or 60 min.
  - "Fixed-time tasks" (on/off), and when on, "Before the task": 5, 10 (default), 15 or 30 min.
  - "End-of-day recap" (on/off), and when on, "Recap time": 15-minute steps from Night's start to 23:45, 23:30 by default.
  - "Running timer alert" (on/off), and when on, "Alert after": 1, 2 (default) or 3 hours.
  - Footer: "A summary when each part starts, a reminder before a part ends, a reminder before fixed-time tasks, a recap of the day, and an alert when a timer has been running a long time."
- **Notifications** status row: "On"; "Off" with an "Open Settings" button that opens the app's notification settings in the system Settings app, and the footer "Notifications are off for Tempo, so no reminders are sent. Turn them on in the Settings app."; or "Not allowed yet" with an "Allow notifications" button that asks for permission (D-067). The status is re-read whenever the app becomes active.
- **Privacy:** "Hide task names on the Lock Screen", off by default. Footer: "Task names stay hidden on the Lock Screen widgets until your iPhone or iPad is unlocked."
- **About:** "Version" shows the marketing version and build, e.g. "1.0 (1)".
- **Validation** (`SettingsValue.validationError`): part times follow F-02; leads and the alert period must be one of their choices; the recap must be a 15-minute step from Night's start to 23:45. A change that breaks a rule isn't saved, and the screen reloads what's stored.
- Times show in the user's 12- or 24-hour format (`TimeOfDayFormatter`).
- Saving refreshes the widgets (and, from T-21, the notifications) through `RefreshManager`.

### Data
`settings` (every column). Reads the notification permission from the system.

### Implementation (iOS)
- Views: `Tempo/Views/Settings/SettingsView`, `SettingsViewModel`.
- Components: `Tempo/Components/MinuteIntervalPicker/MinuteIntervalPicker` (wraps `UIDatePicker`; minutes are shown on a fixed UTC day so daylight saving never shifts them).
- Managers: `Shared/Managers/SettingsManager` (full validation, `SettingsError.invalid`), `NotificationScheduling` with `SystemNotificationScheduler` and `FixedNotificationScheduler` (previews and tests), `NotificationPermission`.
- Rules: `Packages/Core/Sources/Core/Models/SettingsValue.swift` (`validationError`, `recapChoices`, `keepingRecapInRange`).
- Utilities: `Shared/Utilities/Formatters/TimeOfDayFormatter`, `Shared/Utilities/Extensions/DayPart+Title`.

### Tests
- `Packages/Core/Tests/CoreTests/Calendar/SettingsValueTests.swift`: defaults, recap choices, every validation error, the recap following Night.
- `TempoTests/ViewModels/SettingsViewModelTests.swift`: defaults and permission, every setting saved and read back from a new container on the same file (a restart), invalid part times not saved, picker ranges, the recap following Night, asking for permission, "off" status.
- `TempoUITests/SettingsUITests.swift`: every setting is on screen.

### Known gaps
- **Help › How to use** comes with the guide (T-28).
- Settings changes rebuild notifications once they exist (T-21).

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
Status: Partly built (T-07) · Last updated: 2026-10-07 · T-07

### What it does
The next-task rule (SPEC §5.6), shared by this widget and the Lock Screen widgets, exists in `Core`. The widget itself comes in T-26.

### Behavior
- **Candidates:** today's occurrences that are Upcoming or Open, in creation order.
- **The part in progress** is the part whose window contains now. Before Morning's start there's none, so Morning tasks count as a later part ("from 06:00") (D-061).
- **Rules, in order** (`NextTaskRule.pick`):
  1. A fixed-time candidate whose time is now or within the next 60 minutes, earliest first → kind `.fixed(minute:)`.
  2. A candidate in the part in progress: fixed times already passed (earliest first), then part-of-day tasks in creation order. Fixed times more than 60 minutes ahead don't count → `.currentPart(part)`.
  3. The earliest coming item: remaining fixed times at their time (`.fixed`), part-of-day tasks of later parts at their part's start (`.laterPart`). A tie goes to the fixed time, then to creation order.
  4. An Anytime candidate, in creation order → `.anytime`.
  5. Nothing → `nil` ("You're free today").
- **"Then:"** (`NextTaskRule.then`) applies the rule again with the first result removed.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/NextTask/` — `NextTaskRule`, `NextTask`, `NextTaskKind`.

### Tests
- `Packages/Core/Tests/CoreTests/NextTask/NextTaskRuleTests.swift`: the four T-07 cases and their "Then", passed fixed times, creation order, tie-breaking, before Morning, non-candidates, other days.

### Known gaps
- The widget's views, "when" line and "All N tasks done" (T-26).

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
Status: Partly built (T-12–T-15) · Last updated: 2026-10-07 · T-15

### What it does
Screens that can be empty show a message, with an Add button where SPEC F-24 lists one.

### Behavior
| Where | As built |
|---|---|
| Today, no tasks today | "No tasks today" with "Add a task" (editor preset to today) |
| Today, a future day | "Nothing planned for Thu 8 Oct" with "Add a task" (preset to that day) |
| Today, an empty past day | "Nothing was planned for Mon 5 Oct" |
| Today, an empty part | Small grey text, e.g. "Nothing this evening" (wording per day in F-10, D-074) |
| Tasks › Habits | "No habits yet" with "Add a habit" (progress habit preset) |
| Tasks › One-time | "No upcoming tasks" with "Add a task" (one-time preset) |
| History › One-time | "Nothing completed yet" |
| History › Habits | "Finished habits will appear here" |
| History, a search with no results | "No matches" |
| Habit detail, with no data yet | "No data yet. Check back after its first day." |
| Everything else | Not built yet (T-16 onward) |

### Implementation (iOS)
- `ContentUnavailableView` in `Tempo/Views/Today/TodayView.swift`, `Tempo/Views/Tasks/TasksView.swift` and `Tempo/Views/History/HistoryView.swift`.

### Known gaps
- The rest of the F-24 table, with its screens; T-29 checks every row.

## F-25 · iPad
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-25._

## F-26 · Data and future sync
Status: Partly built (T-03) · Last updated: 2026-10-07 · T-04

### What it does
Everything is stored on the device in one SwiftData store inside the App Group, shared by the app and the widget extension. Device-only state lives in the App Group's `UserDefaults`. There's no account and no server.

### Behavior
- **Tables** (SPEC §4): `tasks`, `schedules`, `completions`, `time_entries` and `settings`, one SwiftData record each. Records are flat, link through `UUID` fields, store enums as the SPEC strings (`one_time`, `progress`, `duration`; `fixed`, `part`, `anytime`; `morning` … `night`; `timer`, `manual`) and day keys as `Int`.
- **IDs** are UUIDs made on the device. The settings row's id is always `00000000-0000-0000-0000-000000000001` (D-056).
- **Writes:** `save` inserts or updates a row by id and sets `updatedAt` to the clock's now on every write. `createdAt` keeps the value it was given. `write(_:)` applies several rows in one save: all land, or none do (T-04).
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
- Storage: `Shared/Storage/` — `SchemaV1` (records), `MigrationPlan`, `StoreFactory`, `TaskStore` (protocol), `SwiftDataTaskStore`, `StoreWrite` (atomic batches, T-04), `DeviceState`, `StorageError`.
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
