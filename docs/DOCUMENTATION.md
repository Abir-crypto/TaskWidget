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

Status: Built (T-01–T-36) · Last updated: 2026-10-12 · T-36

### What it does
Tempo is a to-do app for iPhone and iPad (iOS 18 and later) organized by the time of day, with widgets at its core. Every feature in SPEC F-01–F-28 is built, and each section below describes it as it is.

### Behavior
- **App:** four tabs — Today, Tasks, Missed and Stats (F-09) — with Settings, History, Habit detail, the editor, Log time, the timer screen, the task picker, the missed popup and the first-launch guide.
- **Widgets:** Timer, Day, Focus and Now on the Home Screen, and rectangular and inline widgets on the Lock Screen (F-17–F-22).
- **Notifications:** part summaries, ending-soon and fixed-time reminders, an end-of-day recap and the running-timer alert (F-07).
- **iPhone** runs in portrait only. **iPad** supports all four orientations and resizable windows (F-25).
- **App icon:** a ring of four arcs, one per part of the day (amber, orange, pink, violet, clockwise from the top), around a white checkmark on a sky-blue to indigo gradient, with dark and tinted variants for the Home Screen styles (D-099). The widget extension uses the app's icon.
- **Theme color:** eight presets or a custom color in Settings, for the app and its widgets (F-27).
- **Appearance:** System, Dark or Light for the app in Settings; the widgets always follow the device (F-28).
- **Accessibility:** every control has a spoken label and statuses are read as text; layouts hold up to the largest text size; dark mode and the tinted widget styles are supported; completing a task and changing day give haptic feedback (T-31).

### Project and targets
| Item | Value |
|---|---|
| Project / shared scheme | `Tempo.xcodeproj` / `Tempo` (builds the app and extension; tests `TempoTests`) |
| App target | `Tempo`, bundle ID `com.akumatech.tempo`, display name "Tempo" |
| Widget extension | `TempoWidgets`, bundle ID `com.akumatech.tempo.widgets`, embedded in the app |
| App tests | `TempoTests`, bundle ID `com.akumatech.tempo.tests`, hosted in the app |
| UI tests | `TempoUITests`, bundle ID `com.akumatech.tempo.uitests`, in the `Tempo` scheme; the app runs with `-ui-testing` (in-memory store) (D-064) |
| Logic package | `Packages/Core` (Swift 6 tools, iOS 18 and macOS 15), linked into the app and the extension |
| Deployment target | iOS 18.0, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`), set at the project level (D-104) |
| Swift | App, extension and tests use Swift 5 mode with strict concurrency set to `complete` and `InferSendableFromCaptures` on (D-055). Default actor isolation stays `nonisolated` (D-047). |
| App Group | `group.akumatech.tempo`, in both targets' entitlements and `StoreFactory.appGroup` |
| URL scheme | `tempo` (app `Info.plist`) |
| Background refresh | `UIBackgroundModes = [fetch]` and `BGTaskSchedulerPermittedIdentifiers = [com.akumatech.tempo.refresh]`. `TempoApp` handles it with `.backgroundTask(.appRefresh(…))`, and `BackgroundRefresh` schedules the next run after each rebuild (F-07). |
| Signing | Automatic, team `L9B6N63T2Q` (moved from `QAUG82L94Y` on 2026-10-10) |

The folder layout matches ios.md §3. Empty folders hold a `.gitkeep`, which is kept out of the bundles (D-048). `Tempo/`, `TempoWidgets/`, `Shared/` and `TempoTests/` are folder-synchronized groups: a file added on disk joins its target automatically. `Shared/` belongs to both the app and the extension.

### Implementation (iOS)
- App: `Tempo/App/TempoApp.swift` (opens the store, or shows the store error screen; see F-26), `Tempo/Views/Root/RootView.swift` (the tabs, F-09)
- Widgets: `TempoWidgets/TempoWidgetsBundle.swift` and the widget folders (F-17 onward)
- Strings: `Tempo/Resources/Localizable.xcstrings` and `TempoWidgets/Resources/Localizable.xcstrings` (D-046)
- App icon: `Tempo/Resources/Assets.xcassets/AppIcon.appiconset` — `AppIcon.png`, `AppIcon-Dark.png`, `AppIcon-Tinted.png` (1024 × 1024; the first two without transparency, as the App Store requires).
- Config: `Tempo/Info.plist`, `Tempo/Tempo.entitlements`, `TempoWidgets/Info.plist`, `TempoWidgets/TempoWidgets.entitlements`, `.swift-format` (D-049)

### Tests
- `TempoTests/ProjectConfigurationTests.swift`: the app's bundle ID, the `tempo` URL scheme, the background refresh settings, the App Group container (and that the store's App Group is the entitled one), the embedded extension's bundle ID, and that the app and the extension are built for iOS 18.0.
- Each feature section lists its tests. `TempoUITests/AccessibilityUITests` audits every screen (T-31), and `ScreenshotTests` holds the checks on the real Home Screen and Lock Screen (screenshots only).

### Known gaps
- Checked only on simulators. Never seen on a physical device: Lock Screen titles hidden while locked (no simulator can have a passcode), and real Split View and Stage Manager with a second app. Not seen as they happen: widget switches at part boundaries and midnight, a timer running past midnight, a time-zone change while the app runs, and notification kinds other than the fixed-time reminder. The rules behind them are covered by unit tests (T-32).
- Start again's day when the part is over is an open question (D-070, F-03).
- Tests run on the latest installed simulator (iOS 27.0), not on iOS 18, because Xcode 27 can't install iOS 17 or 18 runtimes. The deployment target is iOS 18.0 (D-104), so the compiler rejects newer APIs used without an availability check. A full day on physical devices is planned for T-53.

---

## F-01 · Task types
Status: Built (T-03, T-04, T-11–T-14, T-37, T-38) · Last updated: 2026-10-12 · T-38

### What it does
Tasks are one-time tasks, progress habits or duration habits. The type is set when the task is created; nothing can change it afterward. There's no UI yet.

### Behavior
- Types are stored as `one_time`, `progress` and `duration` (`TaskType`). Progress and duration are habits.
- Titles are trimmed of leading and trailing spaces and newlines, and must then be 1–100 characters (`TaskRules.titleError`: `emptyTitle`, `titleTooLong`).
- One-time tasks have a date; habits have a start day, an optional set length and an optional `ended_on`.
- `TaskManager` has no operation that changes a task's type.
- **Notes** (T-38): every task can have notes. They're trimmed of spaces and line breaks at both ends; empty notes are stored as no value; more than 1,000 characters is refused (`TaskRuleError.notesTooLong`). They're set when the task is created (`createOneTime`/`createHabit` take `notes`) and changed with `setNotes`, wherever the title can change: any habit, ended ones too, and one-time tasks dated today or later (D-119). Notes aren't part of the schedule history, so editing them writes no schedule row. Widgets, Lock Screen widgets and notifications never show them: their content carries titles only.

### Data
`tasks.type`, `tasks.title`, `tasks.notes`.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Models/TaskType.swift`, `Core/Schedule/TaskRules.swift`.
- Manager: `Shared/Managers/TaskManager.swift`.

### Tests
- `Packages/Core/Tests/CoreTests/Schedule/TaskRulesTests.swift`, `TempoTests/Managers/TaskManagerTests.swift`.
- Notes: `TaskRulesTests.notesAreTrimmedEmptyMeansNoneAndLimited`, `TaskManagerTests.notesAreTrimmedClearedAndLimited`, `notesFollowTheTitlesEditingRules`, `moveToTomorrowCopiesTheNotes`, `TaskEditorViewModelTests` (notes for every type, the limit, no schedule row, ended habits), and `TempoTests/Widgets/NotesPrivacyTests.swift` (the Focus and Lock Screen widgets and every planned notification show no notes).

### Known gaps
- None for F-01.

## F-02 · Timing and parts of the day
Status: Built (T-02–T-04, T-10, T-28, T-39) · Last updated: 2026-10-12 · T-39

### What it does
The rules for days, weekdays and parts of the day exist in `Core`. Nothing in the app uses them yet.

### Behavior
- **Day keys** are `yyyymmdd` integers (`DayKey`). They convert to the day's first moment and back in any calendar. Adding days, counting days between two keys and finding a day's weekday all go through the calendar, so month ends, year ends, leap days and daylight-saving days work. `DayKey.distantPast` (`0`) is the `effective_from` of one-time schedules.
- **Weeks** start on the calendar's `firstWeekday`, which comes from the user's region (`startOfWeek`, `week`).
- **Minute of day → moment** (`DayKey.date(atMinute:in:)`, `LocalTime`): builds the wall-clock time in the calendar's time zone. A time inside a daylight-saving gap becomes the first moment after the gap (01:30 on 29 Mar 2026 in London → 02:00 BST, D-053). A repeated time uses its first occurrence (01:30 BST on 25 Oct 2026). Minute 1440 is the next day's midnight.
- **Weekday mask** (`Weekdays`): Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64. Mon/Wed/Fri is 21, every day is 127, and one-time tasks store 0.
- **Names on screen** (T-39, D-106): the part stored as `noon` is called **Afternoon** everywhere the user sees it (`DayPart.title`). Stored values, `noon_start`, notification ids and link parameters keep `noon`.
- **Parts of the day** (`PartSettings`, `DayPart`): defaults Morning 06:00 (360), Afternoon 12:00 (720), Evening 17:00 (1020), Night 21:00 (1260). Each part ends where the next starts, and Night ends at 1440. `part(containing:)` puts minutes before Morning's start into Morning. `window(of:)` is `[start, end)`.
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
- None for F-02.

## F-03 · Habit schedules and goals
Status: Built (T-04, T-06, T-11, T-14, T-15) · Last updated: 2026-10-10 · T-32

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
- Start again starts today even when the habit's part of the day is already over (D-070). That's an open question for the owner.

## F-04 · Daily cycle and status
Status: Built (T-05, T-12, T-16, T-19, T-38) · Last updated: 2026-10-12 · T-38

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
- **Move to tomorrow / Move to next day** (`moveToNextDay`, rule in `Editability.movePlan`): a task that isn't missed changes its date by one day. A task Missed today stays on today as missed, and a copy with the same title, notes and timing is created for tomorrow.
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
- None for F-04.

## F-05 · Time tracking
Status: Built (T-06, T-12, T-15, T-19) · Last updated: 2026-10-10 · T-32

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
- None for F-05.

## F-06 · Timer
Status: Built (T-19, T-20, T-23, T-24) · Last updated: 2026-10-10 · T-32

### What it does
One timer per device, generic or for a habit, which can be paused, resumed, finished or discarded. Its state is stored on the device, shared by the app and the widgets. In the app it shows as a bar above the tabs and a timer screen, with a task picker and a confirmation after Done. Widget controls come in T-23 and T-24.

### Behavior
- **State** (`TimerState`, in `deviceState.timer`): kind (`generic`/`habit`), habit id, the day it started, seconds counted in earlier segments, and the current segment's start (empty while paused). Because it stores moments, the timer keeps going across app restarts and device restarts. If the clock moves backwards, the time counted never goes below zero.
- **One timer:** starting another while one exists (running or paused) throws `TimerError.timerExists`.
- **Habit timer** (`startHabitTimer`): only a duration habit that can receive time today (between its start and last day) (`cantTimeHabit` otherwise). Counting starts immediately.
- **Generic timer** (`startGenericTimer`): no habit; the habit is chosen at Done.
- **Pause / resume** (`pause`, `resume`): any number of times; paused time isn't counted. Pausing a paused timer, or resuming a running one, changes nothing.
- **Done** (`finish`): the clock stops at that moment and the timer is cleared; the result (`FinishedTimer`) carries the frozen whole seconds, the habit (if any) and the day the timer started.
  - **Habit timer** (`finishHabitTimer`): the time is saved straight away as a `timer` entry. Under 60 seconds, nothing is saved (`.tooShort`).
  - **Generic timer:** `save(_:to:)` saves the frozen time to the chosen habit later; time spent choosing isn't counted.
  - The entry always goes to the day the timer started, even after midnight. This is the only way to add time to a past day (`TaskManager.addTimerEntry`), and the habit must be live on that day.
- **Discard** (`discard`): clears the timer and saves nothing.
- **Running alert time** (`nextAlert(periodMinutes:)`): the first whole number of alert periods after the timer was last started or resumed that is still ahead of now, so after "Keep going" it comes back one period later. `nil` while paused. Notifications use it from T-21.
- **Ending or deleting a habit** whose timer exists discards the timer (`TaskManager.endHabit`, `deleteWithHistory`). The app asks first (T-20).
- **For the confirmation** (T-20): `TaskManager.moveTimeEntry` ("Change task") and `undoTimerEntry` ("Undo").
- Every timer change refreshes the widgets through `RefreshManager`.

### Data
`deviceState.timer`; writes `time_entries` with `source = timer`.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Timer/` — `TimerRules`, `TimerState`, `TimerKind`, `FinishedTimer`.
- Manager: `Shared/Managers/TimerManager` (+ `TimerError`, `TimerSaveResult`); `TaskManager.addTimerEntry`, `moveTimeEntry`, `undoTimerEntry`, and the timer discard in `endHabit`/`deleteWithHistory` (`TaskManager` now takes the `DeviceState`).
- App (T-20): `Tempo/App/TimerController` (in the environment), `ActiveTimer`, `TimerToast`, `TaskPickerRequest`; `NavigationRouter.resumePickerAfterEditor`, `editorDidClose`.
- Views (T-20): `Tempo/Components/TimerBar/TimerBar`, `TimerClock`; `Tempo/Components/ConfirmationToast/ConfirmationToast`; `Tempo/Views/TimerScreen/TimerScreenView`; `Tempo/Views/TaskPicker/TaskPickerView`, `TaskPickerViewModel`, `PickerHabit`; ▶ in `Today/Components/DurationRow` and `HabitDetailView`.

### Tests
- `Packages/Core/Tests/CoreTests/Timer/TimerRulesTests.swift`: start, paused time, no-op pause/resume, freezing at Done, the one-minute minimum, 23:40→00:20, a clock moved back, alert times, encoding.
- `TempoTests/Managers/TimerManagerTests.swift`: one timer, which habits can be timed, pause/resume, Done, under a minute, past midnight, Discard, a generic timer's habit, alert times, ending and deleting the timed habit, a restart, Change task and Undo.
- `TempoTests/ViewModels/TimerControllerTests.swift`: ▶ and the bar's state, Done with its confirmation, under a minute, a generic Done through the picker, Undo, Change task, Discard, the picker coming back after adding a task.
- `TempoTests/ViewModels/TaskPickerViewModelTests.swift`: order, progress lines, the empty state, moving.
- `TempoUITests/TimerUITests.swift`: ▶ starts a timer and hides every ▶, the bar on every tab, the timer screen with earlier time, Pause, Done; the picker from a finished generic timer and the confirmation's Undo; the picker's empty state.

### In the app (T-20)
- **▶** ("Start timer"): on Today's duration rows and as "Start timer" in Habit detail, only when no timer exists and the habit can receive time today. It starts a habit timer straight away. Every ▶ is hidden while a timer exists.
- **Timer bar:** while a timer exists, a bar sits above the tab bar on every tab: an icon (timer, or pause when paused), the habit's title or "Timer", the clock counting up (frozen, with "· Paused", while paused), a Pause/Resume button and "Done". Tapping the bar opens the timer screen.
- **Timer screen** (sheet): the title, a large clock, "Paused" when paused, and for habit timers a progress bar with "22 of 30 min today" (time logged earlier today plus the timer, refreshed every 15 seconds); "Pause"/"Resume", "Done", and "Discard" (confirmed with "Discard this timer?" / "Its time won't be saved."). "Close" leaves the timer running. With no timer it shows "No timer running".
- **Done:**
  - Habit timer: the time is saved (under a minute, nothing is saved) and the confirmation appears.
  - Generic timer: the time is frozen and the **task picker** opens. A generic timer finished in the Timer widget opens the same picker through the pending open action.
- **Task picker** (sheet, "Choose a task"): "Add 18 min to" above the duration habits live on the timer's day (today unless it ran past midnight). Habits scheduled that day and still below their target come first, then the rest (past their target, or not scheduled that day), each with "10 of 30 min" or "35 min". Choosing one saves the time and shows the confirmation. "Discard" throws the time away. It can't be swiped away, so the time is never lost by accident. With no duration habits: "No duration tasks yet", "Add a duration task" and "Discard"; Add keeps the time and reopens the picker when the editor closes (D-084).
- **Confirmation:** in the timer bar's place for about 5 seconds: "Added 18 min to Read · 28 of 30 min today" (the day's date instead of "today" for a timer that ran past midnight), with "Undo" (deletes the entry) and "Change task" (opens the picker as "Move 18 min to", leaving out the current habit, and moves the entry). After a timer under a minute: "Less than a minute, nothing saved." (D-086).
- **Ending or deleting a habit with a timer:** the existing confirmations (Today's delete, Habit detail's End habit, the editor's End habit and Delete with history) add "Its running timer will be discarded." (D-085).
- The bar, screen and buttons reload after every change, including timer changes made by a widget.
- Clocks count from the app's clock and then update themselves.

### Known gaps
- None for F-06.

## F-07 · Notifications
Status: Built (T-21, T-28, T-32, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
The app keeps the next 72 hours of reminders scheduled (the earliest 60): part summaries, ending-soon reminders, fixed-time reminders, an end-of-day recap and the running-timer alert. The plan is rebuilt from the current data after every change. Asking for permission comes with the guide (T-28); until then Settings' "Allow notifications" asks.

### Behavior
- **Planning** (`ReminderPlanner`, SPEC §5.9), for every day from today to 72 hours ahead, judged on the data at the time of the rebuild:
  - `part-start.<day>.<part>` at the part's start, when the part has tasks that aren't done. Morning also counts the day's Anytime tasks, and is sent even when only Anytime tasks are left.
  - `ending-soon.<day>.<part>` at the part's end minus the lead (30 min by default), never before the part starts, when the part has tasks that aren't done.
  - `fixed.<task_id>.<day>` at the fixed time minus the lead (10 min by default), when the task isn't done.
  - `recap.<day>` at the recap time (23:30 by default), when the day has tasks that aren't done. Each is classed by its status at the recap time: Missed or Short → "missed", still Upcoming or Open → "still open".
  - `timer-alert` at the timer's next alert time (`TimerRules.nextAlert`), while a timer is running.
  - A duration habit counts as not done until it reaches its target. Each kind is skipped when turned off in Settings. Only notifications after now and within 72 hours are kept, earliest first, at most 60 (iOS allows 64).
- **Words** (`NotificationText`), with lists of up to 3 names then "and N more"; fixed-time tasks read "Interview at 12:30"; duration habits show "(10 of 30 min)" in ending-soon and recap lists:
  - Part starts: "Afternoon · 3 tasks" / "Call the bank, Interview at 12:30, Read". Morning counts its Anytime tasks in the title and adds "…and 2 anytime" to the body; with only Anytime tasks, the body lists them (D-087).
  - Ending soon: "Evening ends in 30 min" (the actual minutes left if the part is shorter than the lead) / "2 left: Gym, Read (10 of 30 min)".
  - Fixed time: "Interview at 12:30" / "In 10 min".
  - Recap: "Today: 2 missed, 1 still open", "Today: 2 missed" or "Today: 1 still open" / the missed then open names. In the Gentle style (F-30): "Today: 1 still open, 2 not done" or "Today: 2 not done"; the body is the same.
  - Timer: "Read timer is still running" or "Timer is still running" / "It's been running for 2 hours."
  - Times follow the user's 12- or 24-hour setting.
- **Delivery:** each notification uses a calendar trigger with year, month, day, hour and minute and no time zone, so reminders float with local time like the tasks. Sound is on. The timer alert has the `TIMER_ALERT` category with "Stop" (opens the app) and "Keep going".
- **Rebuilding** (`ReminderManager.rebuild`) replaces every pending notification. It runs at launch, whenever the app becomes active, after every change (through `RefreshManager`, 0.5 s after a burst of changes; so Settings changes apply at once), on a day change or time zone change, and in the background refresh (`com.akumatech.tempo.refresh`, asked for again each time, no sooner than an hour later). Rebuilds run one at a time; one asked for during another runs once more afterward.
- **Permission:** with permission refused or not yet given, nothing is scheduled (any pending requests are cleared) and nothing fails.
- **While the app is open,** notifications still appear as banners, in the list, with sound.
- **Tapping** a notification opens its place: part summaries and ending-soon → Today at that day and part; fixed time → Today at that task; recap → the Missed tab; timer alert → the timer screen. A tap counts as opening from a link, so the missed popup waits.
- **Timer alert actions:** "Stop" pauses the timer and opens the timer screen; "Keep going" leaves it running and reschedules the alert one period later.
- Taps that arrive before the app has finished starting are kept and handled once it's ready.
- **Permission** is asked for on the guide's last page (F-23), or later from Settings.
- **Real delivery (T-32):** on the iOS 27 simulator a fixed-time reminder arrived on the Home Screen as "Reminder check at 3:05 PM" / "In 10 min", and tapping it opened Today at that task. The first try crashed the app on the tap: the notification delegate used the system's async callbacks, whose completion ran off the main thread. The delegate now uses the completion-handler callbacks and completes on the main actor.

### Data
Reads everything plus `deviceState.timer`; reads the notification permission from the system.

### Implementation (iOS)
- Rules: `Packages/Core/Sources/Core/Reminders/` — `ReminderPlanner`, `PlannedNotification`, `ReminderContent`, `ReminderItem`, `ReminderDestination`.
- Managers: `Shared/Managers/ReminderManager`, `ScheduledNotification`, `NotificationCategory`, `NotificationScheduling` (now with `replacePending`), `SystemNotificationScheduler` (+ `registerCategories`), `FixedNotificationScheduler`; `RefreshManager.reminders`, `refreshNowAndWait`.
- Words: `Shared/Utilities/Formatters/NotificationText`.
- App: `Tempo/App/AppDelegate` (notification delegate, via `UIApplicationDelegateAdaptor`), `NotificationActionHandler`, `NotificationResponse`, `BackgroundRefresh`; rebuild triggers in `TempoApp` and `RootView`.

### Tests
- `Packages/Core/Tests/CoreTests/Reminders/ReminderPlannerTests.swift`: each kind's time and condition, Morning with Anytime, the ending-soon clamp, a lead in the past, recap classes, completing tasks, duration targets, settings toggles and leads, the 48–72 hour horizon and the limit, the timer alert (Keep going, paused, off), past fire times.
- `TempoTests/Notifications/NotificationTextTests.swift`: every F-07 example word for word, "and N more", links.
- `TempoTests/Notifications/ReminderManagerTests.swift`: rebuilds, refused permission, completing a task, Settings changes, the timer alert and its category, rebuilding after any change, overlapping rebuilds.
- `TempoTests/Notifications/NotificationActionHandlerTests.swift`: taps open each place; Stop; Keep going.
- `TempoUITests/ScreenshotTests.swift` (`testFixedTimeReminderArrives`, about 15 minutes): a real fixed-time reminder arrives and its tap opens the app.

### Known gaps
- Only the fixed-time reminder was seen arriving for real. The other kinds go through the same scheduler and tap handling; their times and text are covered by the planner and text tests.

## F-08 · Missed tasks
Status: Built (T-03, T-07, T-16, T-17, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
The Missed tab lists today's Missed and Short tasks, which can still be fixed, and every earlier one, read-only, with sort and filters. A popup points out new missed tasks when the app is opened normally.

### Behavior
- **Today** section: today's Missed and Short occurrences in day order, with the footer "You can still change these". Each row has small buttons where F-04 allows: "Mark done" (one-time and progress), "Log time" (duration; opens the Log time sheet) and "Move to tomorrow" (one-time). A task leaves the section as soon as it's no longer missed. Once a missed task has been copied to tomorrow, "Move to tomorrow" is no longer offered for it, here or on Today (D-081). Empty: "You haven't missed a task today".
- **Earlier** section: every Missed or Short occurrence before today, read-only, grouped under a date line ("Mon, 5 Oct"). The header shows the count after filters ("10 missed"). Ended habits stay; deleted tasks disappear. Empty: "Nothing missed before today"; with filters that match nothing: "No missed tasks match these filters" with "Clear filters".
- **Rows:** the type icon, the title, when it was due ("Tue 29 Sep · Afternoon", "Tue 29 Sep · 12:30", "… · Anytime"), and on the right a red "Missed" with an icon, or the minutes for a Short duration habit ("20 of 30 min", orange).
- **Sort & filter** (the toolbar button, filled while a filter is on; accessibility "Sort and filter" with "Filters on"/"No filters"): a sheet with Sort (Newest first, Oldest first), Date (All, This week, This month, Custom with From and To up to yesterday), Type toggles, Part of the day toggles (Morning, Noon, Evening, Night, Anytime; fixed-time tasks count under their part), and Task (Any task or one task). "Clear filters" appears in the sheet and under Earlier while a filter is on; it keeps the sort order. Changes apply at once. Filters live only while the app runs and reset on restart.
- **"See all" from Habit detail** opens this tab with Earlier filtered to that habit.
- **Badge:** see F-09.
- The tab updates every minute and after every change.
- **Queries** (`Core`): missed today, missed earlier with filters and sort, and unseen (for the popup) as described in SPEC §5.8 (`MissedQueries`, `MissedFilter`).
- **Haptics (T-31):** Mark done gives a light success tap.
- **Large text (T-31):** from the xxLarge text size (and at every accessibility size) the status moves under the title (D-120); at accessibility sizes Mark done, Log time and Move to tomorrow also stack one under another. The status is the shared `StatusLabel`, as on Today (T-40).

### Data
Reads everything through a `Snapshot`; writes completions and copies through `TaskManager`. The popup's seen list is `deviceState.missedSeen` (F-26).

### Implementation (iOS)
- Views: `Tempo/Views/Missed/MissedView`, `MissedViewModel`, `MissedGroup`; `Components/MissedRow`, `MissedFilterSheet`; `Tempo/Views/MissedPopup/MissedPopupView`.
- Popup timing: `Tempo/Views/Root/RootView` (`showMissedPopupIfNeeded`, `markPopupSeen`), `Tempo/App/MissedPopupContent`, `NavigationRouter.missedPopup`, `reviewMissed`, `missedHighlight`.
- Manager: `MissedManager.unseenToday`, `popupItems(openedFromLink:)`, `markSeen`.
- Rules: `Packages/Core/Sources/Core/Missed/` — `MissedQueries`, `MissedFilter`, `MissedDateRange`, `MissedPartFilter`, `MissedSort`, `MissedItem`, `MissedSeenList`; `Core/Schedule/DayOrder`.
- Manager: `TaskManager.hasCopyTomorrow`.

### Tests
- `Packages/Core/Tests/CoreTests/Missed/MissedQueriesTests.swift`, `Schedule/DayOrderTests.swift`.
- `TempoTests/ViewModels/MissedViewModelTests.swift`: today's items and their actions, leaving the section, Move to tomorrow keeping the miss (and not offered twice), date groups and the count, sort and every filter, Clear filters, "See all", filter choices, empty states.
- `TempoUITests/MissedUITests.swift`: Mark done, filters with no matches and Clear filters, empty states.
- `TempoTests/Managers/MissedManagerTests.swift` (`MissedPopupTests`): unseen tasks on a normal open, nothing from a link and the next normal open showing them, seen tasks never shown again, the list resetting the next day, Review.
- `TempoUITests/MissedPopupUITests.swift`: the popup on a normal open, Not now, no popup after returning from the background, Review opening Missed. Other UI tests launch with `-ui-testing-no-popup`.

- **Missed popup** (T-17): when the app is opened normally and today has Missed or Short tasks it hasn't shown yet, a half-height sheet appears over the current screen 0.5 s after the app becomes active (so a widget or notification link that arrives late still counts). It says "You missed 2 tasks today" (grammar-agreed), lists each task with its type icon and timing, and offers "Review missed tasks" and "Not now".
  - Review switches to the Missed tab and highlights those tasks in its Today section (an accent tint) until another tab is chosen.
  - Either button, or swiping the sheet away, counts as having seen its tasks (D-082). Each task appears in the popup only once; the seen list is kept on the device (`deviceState.missedSeen`) and starts over each day.
  - Opening from a widget, a notification or a pending widget action skips the popup until the next normal open; the badge still shows.
  - **Strict only** (F-30): in the Gentle style `MissedManager.popupItems` returns nothing, so the popup never shows. Switching from Gentle to Strict in Settings marks today's tasks missed so far as seen (`markMissedTodaySeen`), so only later misses bring it up.
  - A link that arrives while the popup is open closes it.

### Known gaps
- None for F-08. The end-of-day recap (F-07) lists all of today's missed tasks, including ones the popup has shown.

## F-09 · Navigation and app structure
Status: Built (T-09, T-28, T-29, T-40) · Last updated: 2026-10-12 · T-40

### What it does
The app opens to four tabs. Settings, History, the editor, the timer screen and the task picker open from buttons and from links.

### Behavior
- **Tabs** (left to right): Today (`sun.max`), Tasks (`checklist`), Missed (`exclamationmark.circle`), Stats (`chart.bar`). The app starts on Today.
- **Missed tab name and badge** (F-30): the tab is "Missed" in the Strict style and "Not done" in the Gentle style. The badge, Strict only, is the number of today's Missed and Short tasks; hidden at 0. It's recounted on launch, after every change, when the app becomes active, and every minute (statuses change at part boundaries).
- **Settings** opens from a gear button (accessibility label "Settings") at the top right of Today, pushed onto Today's navigation stack. **History** opens from a clock button ("History") on Tasks, pushed onto Tasks' stack (D-063).
- **Floating + button** ("Add task"): bottom right of Today and Tasks only. Today's opens the editor preset to the selected day (F-10); Tasks' presets the type shown by its segment (a progress habit or a one-time task, F-11). Scrolling content on those screens keeps an 88-point bottom margin, so the last row is never under the button.
- **Timer bar:** every tab's root has the timer bar in a bottom safe-area inset, just above the tab bar, while a timer exists, and the timer's confirmation in the same place after Done (F-06).
- **Presented over the tabs** as sheets: the editor, the timer screen and the task picker (D-063).
- **Links** (`tempo://`, parsed by `DeepLink`):
  - `today[?day=yyyymmdd][&part=…][&task=<uuid>]` → the Today tab; the day, part and task are kept in `NavigationRouter.todayFocus` for the Today screen (T-12).
  - `new[?day=yyyymmdd][&type=one_time|progress|duration]` → the editor with those presets.
  - `missed` → the Missed tab.
  - `timer` → the timer screen.
  - Anything else, or a different scheme, → Today. Unknown or malformed parameters are ignored.
  - Opening a link first closes whatever was presented (a sheet, Settings, History or How to use).
  - Before the first-launch guide is finished, a link waits and opens when the guide closes; so does a widget button's pending action (D-095).
- **Pending open action:** when the app becomes active, a stored "choose a task for the finished timer" action opens the task picker and is cleared.
- **Opened from a link:** a link or pending action marks the activation as not normal (`openedFromLinkThisActivation`), for the missed popup (T-17). It resets when the app goes to the background.
- When the app becomes active, open screens reload, in case a widget changed something.

### Data
Reads today's missed count; reads and clears `deviceState.pendingOpenAction`.

### Implementation (iOS)
- App: `Tempo/App/` — `TempoApp`, `AppDependencies` (now `@Observable`, put in the environment), `NavigationRouter`, `AppTab`, `TodayFocus`, `EditorRequest`, `TaskPickerRequest`, `LaunchOptions` (UI-test launch arguments).
- Views: `Tempo/Views/Root/RootView`, `RootViewModel`; the screens in `Views/` (each feature's section lists its files).
- Components: `Tempo/Components/FloatingAddButton/FloatingAddButton` (with the `floatingAddButton(action:)` modifier), `Tempo/Components/TimerBar/TimerBar` (F-06).
- Links: `Shared/DeepLink/DeepLink.swift`.
- Managers: `Shared/Managers/MissedManager` (badge count); `RefreshManager.revision`, which screens watch to reload.

### Tests
- `TempoTests/Navigation/DeepLinkTests.swift`: parsing every destination and parameter, unknown and malformed links, URLs that parse back.
- `TempoTests/Navigation/NavigationRouterTests.swift`: each link's effect, the pending action, closing presented screens, the link flag.
- `TempoTests/Managers/MissedManagerTests.swift`: the badge count includes Short.
- `TempoUITests/NavigationUITests.swift`: the four tabs, gear → Settings, clock → History, + on Today and Tasks only, every link destination opened in the running app.

### Known gaps
- None for F-09.

## F-10 · Today screen
Status: Built (T-12, T-20, T-31, T-38, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
The Today tab shows one day at a time: a day strip, then Morning, Afternoon, Evening, Night and Anytime, with the actions F-04 allows. It updates every minute while open.

### Behavior
- **Title:** "Today", "Tomorrow", "Yesterday", or a short date in the user's format ("Thu 8 Oct"), as a large navigation title. The gear (Settings) is at the top right. A "Today" button appears at the top left whenever another day is selected.
- **Day strip:** the seven days of the selected day's week, starting on the region's first weekday; each shows its weekday initial and number. Today's number is in the accent color; the selected day is circled (accent for today, black/white otherwise). A grey dot means the day has tasks; a red dot means today or a past day has Missed or Short tasks (D-076). Tapping a day selects it. Swiping the strip left or right moves the selection by a week. VoiceOver reads each day's full date and "No tasks", "Has tasks" or "Has missed tasks", and offers "Next week" and "Previous week" actions.
- **Sections** in order: Morning, Afternoon, Evening, Night, Anytime (`DayPlan`). Within a part, fixed-time tasks come first in time order, then part-of-day tasks in creation order.
  - On today, an ended part with tasks folds into one tappable line, "Morning · 2 done · 1 missed" (Strict; Gentle in F-30) (Short counts as missed), with a chevron; tapping shows or hides its tasks. Expanded parts fold again when another day is selected (D-075).
  - The part in progress has its name in bold accent color and "ends in 1h 20m" on the right, recalculated every minute.
  - Other parts, and every part on other days, show their name as a plain header.
  - A part with no tasks shows small grey text: "Nothing this morning", "Nothing this afternoon", "Nothing this evening", "Nothing tonight" on today; "Nothing in the morning", "Nothing in the afternoon", "Nothing in the evening", "Nothing at night" on other days; "No anytime tasks" for Anytime (D-074).
- **Rows:**
  - One-time tasks and progress habits: a checkbox (accessibility "Mark done"/"Mark not done" with the title), the title (struck through and grey when done), "Habit" with a repeat icon for progress habits, the fixed time on the right if there is one, and a red "Missed" label when missed. The checkbox is disabled where F-04 doesn't allow completing.
  - A task with notes has a small notes icon (`note.text`, spoken "Has notes") after its title, on every row type (T-38).
  - Duration habits: a progress ring, the title, "10 of 30 min", the fixed time if any, "Done", "Short" or "Missed" with an icon once final, and ▶ ("Start timer") while no timer exists and time can be logged today (F-06). Time can still be added after Done.
  - Statuses always come with text and an icon.
- **Tapping a row:** a one-time task opens the editor (read-only for past days); a habit opens Habit detail.
- **Swipe actions**, only where F-04 allows (D-077):
  - From the left: "Done"/"Undo" (one-time and progress, today; one-time on future days), "Log time" (duration habits, today).
  - From the right: "Delete", "Edit" (today and later), "Move to tomorrow" on today or "Move to next day" on a future day (one-time tasks that aren't done; not offered again once a missed task has been copied, D-081).
  - Past days have no swipe actions.
- **Delete:** a one-time task asks "Delete this task?" ("This can't be undone."). A habit asks "End or delete this habit?" with "End habit" and "Delete with history" ("End habit keeps its history and stats. Delete with history removes them for good.", plus "Its running timer will be discarded." when it's being timed).
- **Floating +:** opens the editor preset to the selected day (today when a past day is selected).
- **Links:** `tempo://today?day=…&part=…&task=…` selects the day, unfolds the part (or the task's part) and scrolls to the part or task.
- **Empty states** (F-24): today with no tasks → "No tasks today" with "Add a task"; a future day → "Nothing planned for Thu 8 Oct" with "Add a task" preset to that day; a past day → "Nothing was planned for Mon 5 Oct". The day strip stays visible.
- If an action fails, an alert "Couldn't change the task" explains why.
- Reloads after every change (`RefreshManager.revision`) and when the app becomes active.
- **Log time sheet** (F-05): see F-05.
- **Haptics (T-31):** a light success tap when a task is completed (not on undo), and a selection tick when the shown day changes.
- **Large text (T-31):** from the xxLarge text size, and at every accessibility size, a row's time and status move under its title (`RowDetailsLayout`, D-120), and the day strip stops growing at the largest standard size, with the Large Content Viewer on a long press (D-097).

### Data
Reads everything through a `Snapshot`; writes completions, dates (move), copies, time entries and deletes through `TaskManager`.

### Implementation (iOS)
- Views: `Tempo/Views/Today/TodayView`, `TodayViewModel`; `Components/` — `DayStrip`, `DayStripDay`, `PartHeader`, `CollapsedPartRow`, `TaskRow`, `DurationRow`; `Tempo/Components/StatusLabel` (shared with Missed and Habit detail since T-40).
- Rules: `Packages/Core/Sources/Core/Schedule/DayPlan` (+ `DaySection`, `DayItem`, `DaySectionPhase`).
- Utilities: `Shared/Utilities/Formatters/DayTitleFormatter`, `DurationFormatter`.
- App: `Tempo/App/Route` (Habit detail), `LogTimeRequest`; `NavigationRouter.logTime`.
- `Tempo/App/SampleData` fills previews and UI tests (`-ui-testing-sample`) with a realistic week.
- Large text: `Tempo/Components/RowDetailsLayout` (also used by `MissedRow` and the editor's part rows).

### Tests
- `Packages/Core/Tests/CoreTests/Schedule/DayPlanTests.swift`: section order, items per part, phases, before Morning, other days, counts and progress.
- `TempoTests/ViewModels/TodayViewModelTests.swift`: spec order, statuses at boundaries, collapsing, dots and week moves, titles, read-only past days, F-04 on future days, today's actions including Move to tomorrow, deletes, link focus.
- `TempoUITests/TodayUITests.swift`: checkbox complete/undo, Log time from a swipe, Move to tomorrow from a swipe, swiping the strip by a week and the Today button, unfolding an ended part, disabled checkboxes on past days.

### Known gaps
- None for F-10.

## F-11 · Tasks tab
Status: Built (T-13, T-38) · Last updated: 2026-10-12 · T-38

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
- **Notes icon:** in both lists, a task with notes has the small notes icon after its title (`NotesIndicator`, T-38).
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
- None for F-11.

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
Status: Built (T-15, T-20, T-31, T-38, T-40) · Last updated: 2026-10-12 · T-40

### What it does
Pushed from a habit row in Today, Tasks or History, it shows one habit's schedule, this week, a month calendar, stats, streak, today's time entries and recent missed days.

### Behavior
- **Title bar:** the habit's title, and "Edit" (opens the editor) on the right.
- **Header:** the type with its icon, the title, the schedule summary ("Every day · Evening"), and for duration habits the target ("30 min a day"), then the length: "Day 12 of 30", "Ongoing", "Starts Thu 8 Oct" or "Ended Sat 26 Sep". The notes follow, in full, when there are any (T-38).
- **Buttons:** "Start timer" (▶; duration habits, when time can be logged today and no timer exists), "Log time" (duration habits, when time can be logged today; opens the Log time sheet), and "End habit" (with the confirmation "End this habit?" / "It moves to History with its stats, and you can start it again later.") for an active habit, or "Start again" for an ended one (confirmed with "Started again").
- **This week:** seven days in the region's order, each with an icon and color: done (filled check), short (half circle), missed (filled x), upcoming (empty circle, including today while open), not scheduled (dash). VoiceOver reads the weekday and the result.
- **Month calendar:** the month's grid starting on the region's first weekday. Done days are green, missed red, short pale orange, upcoming outlined; today has an accent ring. Arrows move between months, from the habit's start month up to the current month. A legend (Done, Short, Missed, Upcoming) with icons sits under it. Each day reads its date and result to VoiceOver.
- **Stats:** "This week", "This month" and "This year", each with the completion rate ("—" with no counted days, SPEC §5.7). Duration habits add the time: this week "1h 5m of 3h 30m" (against the weekly goal), the month and year "2h 20m total".
- **Streak:** "Current" and "Best", in days (§5.7).
- **Today's time** (duration habits): each of today's entries with its source ("Timer" or "Logged by hand") and minutes; swipe to delete. "No time logged today" when empty. Past entries never appear here, so they can't be deleted.
- **Recent missed days:** up to 10 Missed or Short days, newest first, including today's (D-080). Short days show "20 of 30 min"; missed days show a red "Missed" with an icon. "See all" switches to the Missed tab with Earlier filtered to this habit (the filter is applied by the Missed tab, T-16).
- **No data yet** (F-24): until the habit has a counted day or any time logged, the week, calendar, stats, streak and missed sections are replaced by "No data yet. Check back after its first day."
- If the habit was deleted, the screen says "This habit no longer exists".
- **Accessibility (T-31):** the month arrows and "See all" have 44-point tap targets, and the target and length line is one sentence that wraps at large text sizes.

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
- None for F-13.

## F-14 · Stats
Status: Built (T-08, T-18, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
The Stats tab shows a week, month or year: an overview, a completion chart, time per duration habit, parts of the day, streaks and each habit's rate. The formulas are SPEC §5.7, computed in `Core`.

### Behavior
- **Range:** a segmented Week / Month / Year picker (Week by default), with the range's title between arrows: "Oct 4–10, 2026", "October 2026" or "2026", in the user's format. Switching kind goes to the period containing today. "Previous" is disabled when the previous range ends before the day the first live task was created; "Next" is disabled when the next range hasn't started.
- **Overview:** the habits' completion rate in large type ("—" with no counted days), with "up 8 points from last week", "down 3 points from last month" or "same as last year" when the previous range has counted days; "Habit days done" ("23 of 28"); "One-time tasks completed"; "Time logged" ("3h 10m").
- **Completion chart:**
  - Week: a bar per day (Swift Charts), 0–100%, colored by completion (green at 100%, paler green from 50%, orange below, red at 0%; grey for days with nothing counted).
  - Month: a calendar grid with each day tinted the same way; future days are faint; today has an accent outline.
  - Year: a bar per month ("Jan" … "Dec").
  - Tapping a day (Week or Month) opens that day in Today (read-only for past days); tapping a month in the Year chart shows that month (D-083). The footer says "Tap a day to open it in Today." or "Tap a month to see it." VoiceOver gets one button per day or month with its date and percentage.
- **Time** (only when there are duration habits in the range): each habit's "1h 5m of 3h 30m" with a progress bar (goal includes days still to come).
- **Parts of the day:** Morning, Afternoon, Evening, Night and Anytime with their rates ("—" when nothing counted), and "Most missed: Evening" (Strict; Gentle in F-30) in the footer when a part qualifies (at least 3 counted).
- **Streaks:** each habit's "Current 3 · Best 4", highest current first.
- **Habits:** each habit live in the range with its rate; tapping opens Habit detail.
- **Empty state** (F-24): with no habits, "Add a habit to see your stats" with "Add a habit" (progress habit preset).
- Reloads after every change and when the app becomes active.
- **Formulas** (T-08, `StatsCalculator`): counted days up to and including today (today only once final), rates rounded half up, change in rounded points, one-time tasks by date up to today, total time, goals including future days, part rates over final statuses, streaks skipping unscheduled days and an open today (D-062).
- **Accessibility (T-31):** the range arrows have 44-point tap targets.

### Implementation (iOS)
- Views: `Tempo/Views/Stats/StatsView`, `StatsViewModel`; `Components/WeekChart`, `MonthGrid`, `YearChart`, `RateColor`.
- Manager: `Shared/Managers/StatsManager`.
- App: `NavigationRouter.showDay(_:)` opens a day in Today without counting as an outside link.
- Rules: `Packages/Core/Sources/Core/Stats/` — `StatsCalculator`, `StatsSnapshot` (+ `DayRate`, `MonthRate`, `HabitTime`, `PartRate`, `HabitStreak`, `HabitRate`), `StatsRange` (+ `StatsRangeKind`), `CompletionRate`, `Streak`.

### Tests
- `Packages/Core/Tests/CoreTests/Stats/StatsCalculatorTests.swift` (formulas, T-08).
- `TempoTests/ViewModels/StatsViewModelTests.swift`: every card for a week, switching kinds, navigation limits, tapping a month, the empty state, tapping a day.
- `TempoUITests/StatsUITests.swift`: the empty state and its button; range limits; tapping a day in the month grid opens it in Today.

### Known gaps
- None for F-14.

## F-15 · Task editor
Status: Built (T-11, T-31, T-38, T-39) · Last updated: 2026-10-12 · T-39

### What it does
A sheet for creating a task or editing one. Presets for the day and type come from where it was opened.

### Behavior
- **Title bar:** "New task", "Edit task", or "Task" when read-only. Cancel (Close when read-only) on the left; Save on the right, disabled until the task is valid.
- **Type:** a segmented One-time / Progress / Duration picker for new tasks, with a one-line explanation under it ("Done once, on one day.", "A habit you check off on the days it repeats.", "A habit measured in minutes against a daily target."). When editing it's shown read-only with "The type can't be changed after a task is created."
- **Title:** a text field. "Add a title" appears in red under it once it has been edited and is empty (D-068).
- **Notes** (T-38): a text field of 3 to 8 lines under the title, placeholder "Notes", for every type. Over 1,000 characters, "Notes can be up to 1,000 characters." appears in red under it and Save is disabled. Saving trims them; clearing them removes them. On an ended habit they stay editable like the title; on a read-only past one-time task they're shown read-only, and the field is left out when there are none.
- **When:** Fixed time / Part of the day / Anytime.
  - Fixed time: a time picker in 5-minute steps.
  - Part of the day: Morning, Afternoon, Evening and Night as rows with a checkmark on the chosen one.
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
- None for F-15.

## F-16 · Settings
Status: Built (T-10, T-28, T-33, T-34, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
Settings is pushed from the gear on Today. Every change is saved as soon as it's made and keeps its value after a restart.

### Behavior
- **Parts of the day:** Morning, Afternoon, Evening and Night, each with a compact time picker in 15-minute steps (`MinuteIntervalPicker`). Each picker only offers start times that keep the parts in order and at least 30 minutes long (`PartSettings.allowedStarts`), so invalid times can't be chosen. Footer: "Each part ends when the next one starts, and Night ends at midnight. Every part lasts at least 30 minutes." If Night moves past the recap time, the recap moves to the first allowed time (D-066).
- **Missed tasks** (T-40): a menu with Gentle (the default) and Strict, under Parts of the day (`MenuValuePicker`). Footer: "Gentle shows tasks you didn't get to as Not done, without a badge or a popup. Strict marks them Missed in red." The choice applies at once to the app (through the `missedStyle` environment value set by `RootView`), the widgets from their next update, and the notifications rebuilt after the change.
- **Reminders**, all on by default:
  - "Part starts" (on/off). Since T-37 the settings row has one switch per part; until T-42 this one switch sets them together (on means Morning's, the default) and any of them on sends every part's summary, as before.
  - "Ending soon" (on/off), and when on, "Before the part ends": 15, 30 (default), 45 or 60 min.
  - "Fixed-time tasks" (on/off), and when on, "Before the task": 5, 10 (default), 15 or 30 min.
  - "End-of-day recap" (on/off), and when on, "Recap time": 15-minute steps from Night's start to 23:45, 23:30 by default.
  - "Running timer alert" (on/off), and when on, "Alert after": 1, 2 (default) or 3 hours.
  - Footer: "A summary when each part starts, a reminder before a part ends, a reminder before fixed-time tasks, a recap of the day, and an alert when a timer has been running a long time."
- **Notifications** status row: "On"; "Off" with an "Open Settings" button that opens the app's notification settings in the system Settings app, and the footer "Notifications are off for Tempo, so no reminders are sent. Turn them on in the Settings app."; or "Not allowed yet" with an "Allow notifications" button that asks for permission (D-067). The status is re-read whenever the app becomes active.
- **Theme:** the app's appearance, System, Dark or Light (F-28), and its color, eight presets or a custom color (F-27).
- **Privacy:** "Hide task names on the Lock Screen", off by default. Footer: "Task names stay hidden on the Lock Screen widgets until your iPhone or iPad is unlocked." The Lock Screen widgets follow it (F-22).
- **Help:** "How to use" opens pages 1–5 of the guide (F-23).
- **About:** "Version" shows the marketing version and build, e.g. "1.0 (1)".
- **Validation** (`SettingsValue.validationError`): part times follow F-02; leads and the alert period must be one of their choices; the recap must be a 15-minute step from Night's start to 23:45. A change that breaks a rule isn't saved, and the screen reloads what's stored.
- Times show in the user's 12- or 24-hour format (`TimeOfDayFormatter`).
- Saving refreshes the widgets and rebuilds the notifications through `RefreshManager`, so a kind turned off or a new lead time applies at once.
- **Large text (T-31):** the part pickers report their real height (at least 44 points), so rows make room for them at every text size.

### Data
`settings` (every column). Reads the notification permission from the system.

### Implementation (iOS)
- Views: `Tempo/Views/Settings/SettingsView`, `SettingsViewModel`.
- Components: `Tempo/Views/Settings/Components/ThemePicker`, `MenuValuePicker` (the lead-time and alert menus, whose value follows the theme, D-101), `Tempo/Components/PartStartPickers/PartStartPickers` (the four part pickers, shared with the guide's page 6), `Tempo/Components/MinuteIntervalPicker/MinuteIntervalPicker` (wraps `UIDatePicker`; minutes are shown on a fixed UTC day so daylight saving never shifts them).
- Managers: `Shared/Managers/SettingsManager` (full validation, `SettingsError.invalid`), `NotificationScheduling` with `SystemNotificationScheduler` and `FixedNotificationScheduler` (previews and tests), `NotificationPermission`.
- Rules: `Packages/Core/Sources/Core/Models/SettingsValue.swift` (`validationError`, `recapChoices`, `keepingRecapInRange`).
- Utilities: `Shared/Utilities/Formatters/TimeOfDayFormatter`, `Shared/Utilities/Extensions/DayPart+Title`.

### Tests
- `Packages/Core/Tests/CoreTests/Calendar/SettingsValueTests.swift`: defaults, recap choices, every validation error, the recap following Night.
- `TempoTests/ViewModels/SettingsViewModelTests.swift`: defaults and permission, every setting saved and read back from a new container on the same file (a restart), invalid part times not saved, picker ranges, the recap following Night, asking for permission, "off" status.
- `TempoUITests/SettingsUITests.swift`: every setting is on screen; the theme's swatches (F-27) and appearance choices (F-28). `GuideUITests` opens How to use.

### Known gaps
- None for F-16.

## F-17 · Widgets: general rules
Status: Built (T-22–T-27, T-33, T-34) · Last updated: 2026-10-11 · T-34

### What it does
The foundation every widget shares: one timeline provider that reads the app's store, entries for each moment the widgets must change, a fallback when the data can't be read, and widget buttons (App Intents) that refresh everything after they act.

### Behavior
- **Data:** each timeline reads a `WidgetSnapshot` — every task row, the settings and the timer — from the App Group store with a fresh context, and the timer from the App Group defaults. It's the same data the app reads (`SnapshotLoader`).
- **Moments** (`TimelinePlanner`, SPEC §5.10): now, each part's start, an hour before and at each fixed time, and midnight, for today and tomorrow; for a running habit timer also the moment its target is reached. Each entry works out statuses for its own moment, so widgets change exactly at part boundaries, at fixed times and at midnight with the app closed. Counting text updates itself in between.
- **Next timeline:** after midnight (`TimelinePlanner.nextMidnight`), and the entries already cover tomorrow in case the refresh is late.
- **Load failure:** a single entry showing "Open Tempo to refresh" with a refresh icon, and another try 15 minutes later.
- **After any change** — in the app, from a widget button or from a notification action — every widget reloads (`WidgetCenter.reloadAllTimelines`) and the notifications are rebuilt (`RefreshManager`). Widget buttons wait for both before returning (`refreshNowAndWait`), since the extension's process may end right after.
- **Widget buttons** (`Shared/Intents/`, compiled into the app and the extension, hidden from Shortcuts with `isDiscoverable = false`): `ToggleCompletionIntent` (the Now widget's checkboxes, a button that carries the state it sets) completes or undoes a task by id and day, following F-04; the timer intents are in F-18 and F-21.
- The T-01 placeholder widget used this provider until the Timer widget replaced it (T-23).
- **Tinted and clear styles (T-31):** main buttons are filled in full color and bordered in the tinted and clear Home Screen styles, where a filled button's label would vanish (`ProminentWidgetButton`). Checked in the Default, Dark, Tinted and Clear styles and at the largest standard text size on the iOS 27 simulator.
- **Theme color (T-33):** the Home Screen widgets are tinted with the theme color from their snapshot's settings (`widgetTheme`), so their accents follow F-27. In the tinted and clear styles and on the Lock Screen, the system's colors apply.
- **Light and dark (T-34):** widgets follow the device's mode. The app's appearance setting (F-28) isn't applied to them.

### Data
Reads everything; buttons write through the same managers as the app.

### Implementation (iOS)
- Shared (app and extension): `Shared/Widgets/WidgetSnapshot`, `SnapshotLoader`, `WidgetTimelinePlan`; `Shared/Intents/IntentEnvironment`, `ToggleCompletionIntent` (D-089).
- Extension: `TempoWidgets/Provider/TodayTimelineProvider`, `TodayEntry`; `TempoWidgets/Components/WidgetFailureView`.
- Rules: `Packages/Core/Sources/Core/Timeline/TimelinePlanner`.
- `TempoWidgets/Components/ProminentWidgetButton` (reads `widgetRenderingMode`).

### Tests
- `Packages/Core/Tests/CoreTests/Timeline/TimelinePlannerTests.swift`: part starts and midnight for two days, fixed times and an hour before, custom part times, the timer's target moment, next midnight.
- `TempoTests/Widgets/WidgetFoundationTests.swift`: a second container on the app's store file (as the extension) reads the same plan; the timeline's moments and refresh time; each moment's statuses; the timer moment; the fallback and 15-minute retry; a widget button completing and undoing, reloading widgets and rebuilding notifications.

### Known gaps
- None for F-17.

## F-18 · Timer widget (small)
Status: Built (T-23) · Last updated: 2026-10-10 · T-31

### What it does
A small widget that starts a generic timer, pauses, resumes and finishes it without opening the app, except Done, which opens the task picker. A habit timer started elsewhere shows here without controls.

### Behavior
- **Gallery:** "Timer" — "Start a timer and choose the habit when you're done." Small only.
- **Idle:** "Timer" with a timer icon and a "Start" button, which starts a generic timer (`StartGenericTimerIntent`) without opening the app. If a timer was started elsewhere in the meantime, nothing happens and the widget catches up.
- **Generic timer, running:** "Timer", the clock counting up (it updates itself), "Running", a pause button ("Pause") and "Done".
- **Generic timer, paused:** the time so far ("5:12" or "1:05:12"), "Paused", a play button ("Resume") and "Done".
- **Done** (`FinishGenericTimerIntent`, opens the app): the time is frozen at the tap, the timer is cleared, and the app opens on the task picker with that time (pending open action). If the intent runs inside the app, it tells the app at once; otherwise the app reads the action when it opens.
- **Habit timer** (started in the app or the Now widget): "Timer", the habit's title, and the clock, or "Paused" with an icon; no buttons.
- **Tapping elsewhere** opens the timer screen while a timer exists, otherwise Today.
- **Load failure:** "Open Tempo to refresh" (F-17).
- The clock, title and main button are accented in tinted and accented styles (`widgetAccentable`). The background is the extension's `WidgetBackground` color.
- Checked on a real Home Screen in the iOS 27 simulator: added from the gallery, Start, Pause, Done opening the task picker, and a habit timer from the app shown without controls.
- **Tinted and clear styles (T-31):** Start and Done use a bordered style, so their labels stay visible.

### Data
Reads `deviceState.timer` and the timed habit's title; writes the timer and `deviceState.pendingOpenAction`.

### Implementation (iOS)
- Widget: `TempoWidgets/Widgets/Timer/TimerWidget`, `TimerWidgetView`; `TempoWidgets/Components/WidgetClock`; previews use `TempoWidgets/Provider/WidgetPreviewData`.
- State: `Shared/Widgets/TimerWidgetState`, `TimerClockValue`.
- Intents: `Shared/Intents/StartGenericTimerIntent`, `PauseTimerIntent`, `ResumeTimerIntent`, `FinishGenericTimerIntent` (+ `Notification.Name.pendingOpenActionWritten`).
- App: `RootView.handlePendingOpenAction`, run on activation and on that notification.
- The T-01 placeholder widget is gone; `TempoWidgetsBundle` lists `TimerWidget`.

### Tests
- `TempoTests/Widgets/TimerWidgetTests.swift`: idle and its link; Start, Pause and Resume through the intents; Done freezing the time and leaving the picker action; a habit timer shown without controls (and the generic Done leaving it alone); Start while a timer exists; paused clock text.
- `TempoUITests/ScreenshotTests.swift` (`testWidgetOnHomeScreen`, `testTimerWidgetButtons`, `testTimerWidgetShowsAHabitTimer`, run only with `TEST_RUNNER_TEMPO_SCREENSHOTS`): adds the widget through SpringBoard and photographs every state.

### Known gaps
- None for F-18.

## F-19 · Day widget (medium)
Status: Built (T-25, T-39, T-40) · Last updated: 2026-10-12 · T-40

### What it does
A medium widget showing today part by part: a column of marks for Morning, Afternoon, Evening and Night. It has no buttons.

### Behavior
- **Gallery:** "Day" — "Your day at a glance, part by part." Medium only.
- **Columns:** Morning, Afternoon, Evening and Night (titles shrink to fit, down to 70%). The part in progress has its name in bold accent color on a light accent background.
- **Marks,** one per task in day order, each an icon with a color: ✓ done (green filled check), ○ not done yet (empty circle), ✗ missed (red x; in the Gentle style a grey – , F-30), ◐ short, or a duration habit with some time logged that isn't done (orange half circle). At most 6 per column, then "+N".
- **Under each column:** "N left" (tasks still Upcoming or Open), "done" when none are left, or nothing when the part has no tasks.
- **Footer:** "Anytime · N left" while Anytime tasks are open; "You're free today" when every task today is done (every mark is then ✓).
- **Tapping a column** opens Today at that part; tapping elsewhere opens Today.
- **No tasks today:** "No tasks today" with a sun icon; tapping opens the editor for today.
- **Load failure:** "Open Tempo to refresh" (F-17).
- VoiceOver reads each column as its part name with "2 done, 1 missed, 3 left" or "No tasks".
- Checked on a real Home Screen in the iOS 27 simulator.
- **Without the widget background** (StandBy, some styles) the current part keeps its bold accent name but drops its fill (T-31).

### Implementation (iOS)
- Widget: `TempoWidgets/Widgets/Day/DayWidget`, `DayWidgetView`.
- Content: `Shared/Widgets/DayWidgetContent`, `DayColumn`, `DayMark`.

### Tests
- `TempoTests/Widgets/DayWidgetTests.swift`: columns, the highlight, every kind of mark, "N left" and "done", "+N", the Anytime footer, the empty and all-done states, column links.
- `TempoUITests/ScreenshotTests.swift` (`testDayWidgetOnHomeScreen`, screenshots only).

### Known gaps
- None for F-19.

## F-20 · Focus widget (medium)
Status: Built (T-07, T-26, T-39) · Last updated: 2026-10-12 · T-39

### What it does
A medium widget with the one thing to do next, from the next-task rule (SPEC §5.6), and what comes after it. Information only, with no buttons.

### Behavior
- **Gallery:** "Focus" — "The one thing to do next, and what comes after." Medium only.
- **Top line** (bold, accent color), from the rule's reason:
  - a fixed-time task: "NEXT · 12:30 · in 45 min", where "in 45 min" counts down by itself;
  - a task in the part in progress: "AFTERNOON · until 17:00";
  - a task in a later part: "EVENING · from 17:00";
  - an Anytime task: "ANYTIME".
  Times follow the user's 12- or 24-hour setting.
- **Title,** large, up to two lines.
- **Duration habits:** "10 of 30 min" with a timer icon.
- **"Then:"** and the title of the next item after it (the rule applied again without the first), when there is one.
- **Nothing left:** "You're free today", plus "All 6 tasks done" when today had tasks and every one is done. If some were missed, only "You're free today" shows (D-091).
- **Tapping** opens Today at the task shown, or Today when free.
- **Updates on its own:** the timeline has entries at each part's start and an hour before and at each fixed time (F-17), so the shown task changes at those moments; the countdown updates in between.
- **The rule** (`NextTaskRule`, T-07): candidates are today's Upcoming or Open occurrences; (1) a fixed time within the next 60 minutes, earliest first; (2) the part in progress — passed fixed times first, then part-of-day tasks in creation order; (3) the earliest coming item, fixed times at their time and later parts at their start, a tie going to the fixed time; (4) Anytime in creation order; (5) nothing. Before Morning's start, no part is in progress (D-061).
- **Load failure:** "Open Tempo to refresh" (F-17).
- Checked on a real Home Screen in the iOS 27 simulator.

### Implementation (iOS)
- Widget: `TempoWidgets/Widgets/Focus/FocusWidget`, `FocusWidgetView`.
- Content: `Shared/Widgets/FocusWidgetContent`, `NextTaskItem`, `NextTaskWhen` (shared with the Lock Screen widgets since T-27), and `WidgetSnapshot.allDoneCount` for "All N tasks done".
- Rules: `Packages/Core/Sources/Core/NextTask/` — `NextTaskRule`, `NextTask`, `NextTaskKind`.

### Tests
- `Packages/Core/Tests/CoreTests/NextTask/NextTaskRuleTests.swift` (the rule).
- `TempoTests/Widgets/FocusWidgetTests.swift`: the four "when" lines with their "Then:", duration progress, the free state with and without "All N tasks done", the tap link, and the shown task changing across the timeline's moments.
- `TempoUITests/ScreenshotTests.swift` (`testFocusWidgetOnHomeScreen`, screenshots only).

### Known gaps
- None for F-20. The Lock Screen widgets (F-22) use the same rule.

## F-21 · Now widget (large)
Status: Built (T-24, T-40) · Last updated: 2026-10-12 · T-40

### What it does
A large widget with what's on now and next: checkboxes that complete and undo without opening the app, and ▶ that turns the widget into the habit's timer.

### Behavior
- **Gallery:** "Now" — "What's on now and next. Check off tasks and time habits." Large only.
- **List mode:**
  - The header is the first group's part: its name, "ends in 3 hr, 50 min" (updating itself) for the part in progress or "from 17:00" for a later part, and "N left" (tasks still to do in that part). (T-26 fixed a missing "in".)
  - Groups: the part in progress when it has tasks, otherwise the next part with tasks; then the next part with tasks after that, under its own small header; then Anytime. At most 8 rows (the first group's header doesn't count); the rest become "+N more", which opens Today.
  - One-time and progress rows: a round checkbox and the title (struck through when done) and the fixed time if any. Tapping the checkbox marks the task done, or not done, without opening the app (`ToggleCompletionIntent`, a button that carries the state it sets, D-090).
  - Duration rows: a timer icon (a check once the target is reached), the title, "10 of 30 min", and ▶ while no timer exists (`StartHabitTimerIntent`), which starts the habit's timer without opening the app.
  - Footer: "2 missed today ›" (red, with an icon) when today has Missed or Short tasks; it opens the Missed tab. In the Gentle style: "2 not done today ›" in grey, with a dash icon (F-30).
  - While a generic timer exists, a line "Timer running · 5:12" (updating itself) sits at the top, and every ▶ is hidden.
  - "You're free today" when nothing is left today (the missed footer still shows); "No tasks today" when today has no tasks, and tapping opens the editor for today.
  - Tapping elsewhere opens Today.
- **Timer mode** (while a habit timer exists, started here, in the app or anywhere else): "Timer", the habit's title, the clock (or "Paused"), a progress bar toward today's target that fills by itself while running, "22 of 30 min today", Pause/Resume, Done and Discard. Done (`FinishHabitTimerIntent`) saves the time without opening the app (nothing under a minute) and returns to the list; Discard (`DiscardTimerIntent`) saves nothing and returns to the list. Tapping elsewhere opens the timer screen. The Timer widget shows the same timer, display only.
- **Load failure:** "Open Tempo to refresh" (F-17).
- Checked on a real Home Screen in the iOS 27 simulator: added from the gallery, list mode, and a checkbox tap completing the task in the app.
- **Tinted and clear styles (T-31):** timer mode's Done uses a bordered style, so its label stays visible.

### Data
Reads everything through the widget snapshot; writes completions, the timer and time entries through the intents.

### Implementation (iOS)
- Widget: `TempoWidgets/Widgets/Now/NowWidget`, `NowWidgetView`, `NowListView` (list mode), `NowTimerView` (timer mode); `TempoWidgets/Components/WidgetCheckbox`, `WidgetClock`.
- Content: `Shared/Widgets/NowWidgetContent`, `NowList`, `NowTimer`.
- Intents: `Shared/Intents/StartHabitTimerIntent`, `FinishHabitTimerIntent`, `DiscardTimerIntent`, `ToggleCompletionIntent`, `PauseTimerIntent`, `ResumeTimerIntent`.

### Tests
- `TempoTests/Widgets/NowWidgetTests.swift`: group order, an empty current part, "+N more", free and empty states, checkboxes completing and undoing, ▶ turning the widget into the timer (and the Timer widget showing it), Done saving, Discard, the generic-timer line hiding ▶.
- `TempoUITests/ScreenshotTests.swift` (`testNowWidgetOnHomeScreen`, `testNowWidgetCheckbox`, screenshots only).

### Known gaps
- None for F-21.

## F-22 · Lock Screen widgets
Status: Built (T-07, T-27, T-39) · Last updated: 2026-10-12 · T-39

### What it does
Two Lock Screen widgets with the one thing to do next, from the next-task rule (SPEC §5.6): a rectangular one under the clock (two lines) and an inline one above it (one line). Information only.

### Behavior
- **Gallery:** "Next task" — "Your next task, on the Lock Screen." Rectangular and inline.
- **Rectangular,** first line (bold, accent color) / title (up to two lines):
  - a fixed-time task: "12:30 · in 45 min" / "Interview", where "in 45 min" counts down by itself;
  - a task in the part in progress: "Afternoon · until 17:00" / "Call the bank";
  - a duration habit: "Evening · 10 of 30 min" / "Read" — its time, part or "Anytime", then its progress, whatever its timing (D-092);
  - a task in a later part: "Evening · from 17:00" / "Gym";
  - an Anytime task: "Anytime" / "Renew passport";
  - nothing left: "You're free today" / "All 6 tasks done", the second line only when today had tasks and every one is done (D-091).
  The first line shrinks to fit (down to 70%) rather than being cut off, since "Morning · until 12:00 PM" is wider than the widget at the headline size.
- **Inline:** "Next: Interview at 12:30", "Afternoon: Call the bank", "Evening: Read", "Evening: Gym", "Anytime: Renew passport", or "You're free today".
- Times follow the user's 12- or 24-hour setting.
- **Hide task names on the Lock Screen** (F-16): titles are marked privacy-sensitive, so the system hides them while the device is locked and shows them once it's unlocked. On the inline widget the whole line is hidden, since it's a single line of text (D-092). Turning the setting on or off refreshes the widgets.
- **Tapping** opens Today at the task shown, or Today when free.
- **Updates on its own** at the same moments as the other widgets (F-17); the countdown updates in between.
- **Load failure:** "Open Tempo to refresh", with a refresh icon on the inline size (F-17).
- Checked on a real Lock Screen in the iOS 26.5 simulator, on iPhone and on iPad (T-30): both sizes, the shrinking first line, and a tap opening Today at the task. The iOS 27 simulator can't edit the Lock Screen, and no simulator can have a passcode, so the hidden names were not seen locked; the `Names hidden while locked` preview shows how they're drawn.

### Implementation (iOS)
- Widget: `TempoWidgets/Widgets/LockScreen/LockScreenWidget`, `LockScreenWidgetView` (`.accessoryRectangular`, `.accessoryInline`; `.privacySensitive()` on titles).
- Content: `Shared/Widgets/LockScreenWidgetContent`, `LockScreenItem`, built on `NextTaskItem` and `NextTaskWhen`, which the Focus widget uses too.
- Rules: `Packages/Core/Sources/Core/NextTask/` — `NextTaskRule` (F-20).

### Tests
- `TempoTests/Widgets/LockScreenWidgetTests.swift`: every row of the F-22 table on both sizes; duration habits at a fixed time, in a later part and at Anytime; the free state with and without "All N tasks done"; the tap link; "Hide task names" reaching the widget and refreshing it; the shown task changing across the timeline's moments.
- `TempoUITests/ScreenshotTests.swift` (`testLockScreenWidgets`, screenshots only; run on the iOS 26.5 simulator).

### Known gaps
- Titles hidden while locked can only be seen on a device with a passcode.

## F-23 · First-launch guide
Status: Built (T-28) · Last updated: 2026-10-10 · T-29

### What it does
Seven swipeable pages shown once, over everything, the first time the app opens: five that introduce the app, one to set the parts of the day, and one to allow notifications. Settings › How to use shows the first five again.

### Behavior
- **Pages,** each with an SF Symbol, a title and one or two sentences:
  1. "Welcome to Tempo" — "Plan your day by its parts: morning, noon, evening and night. Every task belongs to a part, a set time, or anytime."
  2. "Three kinds of tasks" — "One-time tasks are done once. Progress habits are checked off on their days, and duration habits count minutes toward a daily target."
  3. "Reminders" — "A summary as each part starts, a reminder before it ends, and a look at anything you missed."
  4. "Widgets" — "Timer runs a stopwatch, Day shows the whole day, Focus shows what's next, and Now lets you check tasks off. On the Lock Screen, you'll see your next task."
  5. "Missed and Stats" — "Missed gathers what slipped by, so you can still do it or move it to tomorrow. Stats shows your streaks and how each part of the day is going."
  6. "Your parts of the day" — "Choose when each part starts. You can change these later in Settings." Then the four start-time pickers from Settings (15-minute steps, limited by the F-02 rules), filled with the stored times — the defaults on first launch. Each change is saved straight away.
  7. "Notifications" — "Allow notifications for part summaries, reminders and an end-of-day recap." **Allow** asks for the system permission, schedules the reminders and closes the guide; **Not now** closes it without asking.
- **Moving between pages:** swipe, or tap **Next** at the bottom of pages 1–6. Page dots show where you are (D-093).
- **Skip** (top right, pages 1–5) jumps to page 6, so the setup pages are never skipped.
- Closing page 7, either way, marks the guide completed; it never shows on its own again. Closing the app before then shows it again next time, keeping any part times already saved. The guide can't be swiped away.
- A link (for example a tap on an empty widget) or a widget button's pending action that arrives before the guide is finished waits, and opens when the guide closes (D-095).
- The missed popup waits while the guide is showing. Today's empty state appears once it closes.
- **How to use** (Settings › Help) opens pages 1–5 with **Done** at the top right instead of Skip, and Done instead of Next on page 5. It doesn't change whether the guide was completed. A link from a widget or notification closes it; the first-launch guide stays until it's finished (D-093).

### Data
Writes the part times in `settings` (page 6). Device-only: "guide completed" (`DeviceState.guideCompleted`, D-094).

### Implementation (iOS)
- Views: `Tempo/Views/Onboarding/OnboardingView`, `OnboardingViewModel`, `OnboardingPage`; `Components/OnboardingPageView`.
- Presented by `RootView` with `.fullScreenCover(item: $router.guide)`; `GuideMode` (`firstLaunch`, `howToUse`) in `Tempo/App`.
- Page 6 uses `SettingsViewModel` and `Tempo/Components/PartStartPickers` (shared with Settings).
- `-ui-testing-guide` shows the guide in UI tests, which otherwise skip it.

### Tests
- `TempoTests/ViewModels/OnboardingViewModelTests.swift`: seven pages in order, Skip only on pages 1–5 and leading to page 6, page 6 saving part times, Allow asking and scheduling, Not now not asking, both marking the guide completed, How to use's five pages leaving it unchanged.
- `TempoTests/Storage/DeviceStateTests.swift`: "guide completed" survives a restart and is cleared by a reset.
- `TempoUITests/GuideUITests.swift`: the guide on first launch (Next, swipe, Skip to page 6 and its pickers, Allow, then Today), other launches without it, and How to use from Settings.
- `TempoUITests/ScreenshotTests.swift` (`testGuide`, screenshots only).

### Known gaps
- None for F-23.

## F-24 · Empty states
Status: Built (T-12–T-29, T-40) · Last updated: 2026-10-12 · T-40

### What it does
Every place that can be empty shows a message, with an Add button where SPEC F-24 lists one. T-29 checked every row in the running app and the widgets.

### Behavior
| Where | As built |
|---|---|
| The app opened for the first time | The guide (F-23), then "No tasks today". A link that arrives first waits for the guide (D-095). |
| Today, no tasks today | "No tasks today" with "Add a task" (editor: one-time, today) |
| Today, a future day | "Nothing planned for Thu 8 Oct" with "Add a task" (editor: one-time, that day) |
| Today, an empty past day | "Nothing was planned for Mon 5 Oct", no button |
| Today, an empty part | Small grey text, e.g. "Nothing this evening" (wording per day in F-10, D-074) |
| Tasks › Habits | "No habits yet" with "Add a habit" (editor: progress habit) |
| Tasks › One-time | "No upcoming tasks" with "Add a task" (editor: one-time, today) |
| History › One-time | "Nothing completed yet" |
| History › Habits | "Finished habits will appear here" |
| History, a search with no results | "No matches" |
| Missed › Today | "You haven't missed a task today"; Gentle: "Nothing left undone today" |
| Missed › Earlier | "Nothing missed before today"; Gentle: "Nothing undone before today" |
| Missed, filters with no results | "No missed tasks match these filters" with "Clear filters"; Gentle: "No tasks match these filters" |
| Stats, with no habits | "Add a habit to see your stats" with "Add a habit" (editor: progress habit) |
| Habit detail, with no data yet | "No data yet. Check back after its first day." |
| Task picker, with no duration habits | "No duration tasks yet" with "Add a duration task" (editor: duration habit; the picker comes back after, D-084) and "Discard" |
| Day and Now widgets, with no tasks | "No tasks today" with a sun icon; tapping opens the editor for today (one-time) |
| Now widget, nothing left | "You're free today" |
| Day widget, everything done | Every mark ✓ and "You're free today" |
| Focus widget, nothing left | "You're free today", plus "All N tasks done" when every task was done |
| Lock Screen widgets, nothing left | Rectangular: "You're free today" (plus "All N tasks done"); inline: "You're free today" |
- The editor presets come from `EditorRequest.new(day:type:)`.
- Checked on the iOS 27 simulator: every app row by `EmptyStatesUITests` and the tests listed below; the Now and Focus widgets' empty states on the real Home Screen, and tapping the empty Now widget, which opened the guide and then the editor for today.

### Implementation (iOS)
- `ContentUnavailableView` in `TodayView`, `TasksView`, `HistoryView`, `StatsView`, `HabitDetailView` and `TaskPickerView`; Missed's section messages and the empty parts' grey text are plain `Text` in `MissedView` and `TodayView`.
- Widgets: `DayWidgetView`, `NowListView`, `FocusWidgetView`, `LockScreenWidgetView`.

### Tests
- `TempoUITests/EmptyStatesUITests.swift`: Today (no tasks, a future day, an empty past day, empty parts), Tasks › Habits and One-time, Stats, Habit detail and the task picker, tapping each Add button and checking the editor's type and date; the empty widgets' link opening the editor for today.
- `HistoryUITests`, `MissedUITests` (`testEmptyStates`), `StatsUITests` (`testEmptyState`) and `TimerUITests` (`testPickerEmptyState`) cover the History, Missed, Stats and task picker messages.
- Widgets: `DayWidgetTests`, `NowWidgetTests` (`freeAndEmptyStates`), `FocusWidgetTests` and `LockScreenWidgetTests` (`freeWhenNothingIsLeft`).
- `GuideUITests.testLinkOpensAfterTheGuide`, `NavigationRouterTests.linkWaitsForTheFirstLaunchGuide` (D-095).
- `ScreenshotTests.testEmptyNowWidgetOpensTheEditor` (screenshots only).

### Known gaps
- None for F-24.

## F-25 · iPad
Status: Built (T-30) · Last updated: 2026-10-10 · T-30

### What it does
The same app on iPad, with content kept to a readable width, every orientation, and resizable windows that look like the phone when narrow.

### Behavior
- **Readable width:** on screens wider than 700 points, the rows of Today, Tasks, Missed, Stats, History, Habit detail and Settings keep to 700 points, centered; the list, its grey background and its scrolling fill the screen. Today's day strip, the Tasks and History segmented controls, the timer bar and the timer confirmation keep to the same width. Narrower screens keep the usual margins (D-096).
- **Sheets** (editor, Log time, timer screen, task picker, missed popup) open as the system's form sheets on iPad, already narrower than 700 points. The guide's pages keep to 560 points.
- **Navigation:** on iPad the four tabs show at the top of the screen, as the system draws a tab view there; in a narrow window they move to the bottom, as on the phone. Navigation titles and the floating + button stay at the screen's edges.
- **Orientations:** iPad supports all four; iPhone stays portrait.
- **Multitasking:** windows can be resized; a narrow window shows the phone layout.
- **Widgets:** Timer, Day, Focus and Now on the iPad Home Screen, and both Lock Screen widgets on the iPad Lock Screen, look and work as on iPhone.
- Checked on the iPad Pro 13-inch simulator (iOS 27.0): every screen in portrait and landscape, a window dragged narrow and back, and the four Home Screen widgets with a real task. The Lock Screen widgets were checked on the iOS 26.5 iPad simulator, whose Lock Screen editor works: both sizes added, shown locked, and a tap opening Today.

### Implementation (iOS)
- `Shared/Utilities/Extensions/View+ReadableWidth` (`readableWidth()`, `readableScrollContent()`), `Shared/Utilities/Layout/ReadableWidth`, `ReadableScrollContent`.
- Used in `TodayView`, `TasksView`, `MissedView`, `StatsView`, `HistoryView`, `HabitDetailView`, `SettingsView` and `Components/TimerBar`.
- Orientations: `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` (all four); `UIRequiresFullScreen` isn't set, so multitasking works.

### Tests
- `TempoTests/Utilities/ReadableWidthTests.swift`: the margins for phone, iPad mini, and iPad Pro portrait and landscape widths.
- `TempoUITests/ScreenshotTests.swift` (screenshots only): `testEveryScreenInBothOrientations`, `testNarrowWindow`, `testWidgetsOnIPadHomeScreen`, `testLockScreenWidgets` (also runs on iPad).

### Known gaps
- Split View and Stage Manager were checked only by resizing the app's window from a UI test, not by placing a second app beside it.

## F-26 · Data and future sync
Status: Built (T-03, T-04, T-22, T-28, T-33, T-34, T-37) · Last updated: 2026-10-12 · T-37

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
- **Device-only state** (SPEC §4.6), one JSON value per key in `UserDefaults(suiteName: "group.akumatech.tempo")`:
  - `deviceState.timer` — the timer: kind (`generic`/`habit`), habit id, start day, accumulated seconds, current segment start (empty while paused).
  - `deviceState.missedSeen` — the popup's seen list: a day and occurrence ids.
  - `deviceState.pendingOpenAction` — for now only "choose a task for a finished timer", with the frozen time.
  - `deviceState.guideCompleted` — a plain bool: the first-launch guide was finished (D-094).
  - `deviceState.snoozes` — the day's snoozed reminders: a day, and for each snooze the original reminder's id, its kind (`fixed` or `ending_soon`), its fire time and its day. A list for another day reads as empty, so snoozes clear when the day changes (T-37; used from T-43).
  - `deviceState.addWidgetCardClosed` — a plain bool: the Add a widget card was closed (T-37; used from T-50).
  - `deviceState.proEntitlement` — whether Tempo Pro is unlocked and when the store last confirmed it (T-37; used from T-51).
  - Setting a value to empty removes the key. A value that can't be decoded reads as empty and is logged.
- **Sharing with the widgets:** the store file is `Tempo.store` in the App Group container. Every read and write makes a fresh `ModelContext`, so each process sees the other's writes (CLAUDE.md, ios.md §6).
- **If the store can't be opened,** the app shows "Can't open your tasks" / "Something went wrong while opening Tempo's data. Close the app and open it again." (D-057).
- **After every write** through a manager, `RefreshManager.afterChange()` reloads every widget and rebuilds the notifications, 0.5 s after the last of a burst of writes. `refreshNow()` skips the wait; `refreshNowAndWait()` also waits for the notifications, for App Intents (T-21).
- **Schema versions:** version 2 (T-33) adds `settings.tint_color`, and version 3 (T-34) adds `settings.appearance`. Version 4 (T-37) adds `tasks.notes`, replaces `settings.notify_part_start` with one switch per part (`notify_part_start_morning` on; `_noon`, `_evening` and `_night` off), and adds `settings.missed_style` (`gentle`). Older stores migrate through lightweight stages, V1 → V2 → V3 → V4, and keep their data; the old single part-start switch isn't carried over, so every store gets the new defaults.
- **Notes** (`tasks.notes`): trimmed of spaces and line breaks at both ends; empty notes are stored as no value; more than 1,000 characters is rejected (`TaskRuleError.notesTooLong`). `TaskManager.setNotes(taskID:notes:)` changes them wherever the title can change (T-37; the editor uses it from T-38).
- **Missed style** (`settings.missed_style`): `gentle` or `strict`; anything else reads as `gentle` (`MissedStyle`). Stored from T-37; shown from T-40.

### Data
All tables in SPEC §4 and the device-only state in §4.6.

### Implementation (iOS)
- Values: `Packages/Core/Sources/Core/Models/` — `TaskValue`, `TaskType`, `ScheduleValue`, `Timing`, `TimingKind`, `CompletionValue`, `TimeEntryValue`, `TimeEntrySource`, `SettingsValue`, `ThemeColor`, `ThemePreset`, `Appearance`, `MissedStyle`, `Snooze` (with `SnoozeKind` and `SnoozeList`), `ProEntitlement`, `TaskData`, `PendingOpenAction`; `Core/Timer/` — `TimerState`, `TimerKind`, `FinishedTimer`; `Core/Missed/MissedSeenList`.
- Storage: `Shared/Storage/` — `SchemaV1`, `SchemaV2`, `SchemaV3`, `SchemaV4` (records), `MigrationPlan`, `StoreFactory`, `TaskStore` (protocol), `SwiftDataTaskStore`, `StoreWrite` (atomic batches, T-04), `DeviceState`, `StorageError`.
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

## F-27 · Theme color
Status: Built (T-33, T-34, T-40) · Last updated: 2026-10-12 · T-40

### What it does
Settings › Theme sets the app's color: eight presets or a custom color. It colors the whole app at once, and the Home Screen widgets' accents from their next update.

### Behavior
- **Settings › Theme**, between Notifications and Privacy, below Appearance (F-28): swatches for Blue (the default), Indigo, Purple, Pink, Red, Orange, Green and Teal, then Custom, a color well that opens the system color picker without opacity. The chosen swatch has a checkmark and a ring; the Custom well shows the custom color once one is chosen, and Blue before (D-100). Each swatch is a 44-point target named for VoiceOver ("Purple"; "Custom", with the color's name as its value). The section's footer: "System follows your device's light or dark mode, as the widgets always do. The color is used for buttons, checkboxes and highlights in the app and its widgets."
- **In the app,** the choice is saved at once and colors: the tab bar's selected tab, the day strip's selected day, the part in progress and its "ends in", checkboxes, progress rings and bars, the + and ▶ buttons, switches, links and buttons on every screen and sheet, Settings' menu values, the plain options in confirmation dialogs, the guide, Missed's buttons and its highlight, and Stats' and Habit detail's arrows. Presets are the system colors, with a light and a dark shade; a custom color is the same in both modes.
- **Widgets:** the Timer widget's buttons, the Day widget's current part, the Focus widget's top line and the Now widget's buttons and progress follow the theme from their next update (choosing a color refreshes them). The Lock Screen widgets and the tinted and clear Home Screen styles use the system's colors (F-17).
- **Unchanged:** the status colors (done green, missed red in the Strict style or grey in the Gentle style (F-30), short orange, always with an icon or text), destructive buttons (red), and the app icon.
- A stored color that can't be read is Blue.
- Checked on the iOS 27 simulator: every screen with Pink in light mode and Indigo in dark mode, and the Timer, Day, Focus and Now widgets on a real Home Screen with Pink.

### Data
`settings.tint_color` (SPEC §4.5): a preset's name (`blue` … `teal`) or `#RRGGBB`. Stores from before T-33 migrate with their data (`SchemaV2`, lightweight stage from V1; F-26).

### Implementation (iOS)
- Core: `Packages/Core/Sources/Core/Models/ThemeColor` (parsing and writing the stored string), `ThemePreset`; `SettingsValue.tintColor`.
- Storage: `Shared/Storage/SchemaV2` (and `SchemaV3` since T-34), `MigrationPlan`; `SwiftDataTaskStore` maps `tintColor`.
- Utilities: `Shared/Utilities/Extensions/ThemeColor+Color`, `ThemePreset+Style` (system color and name).
- App: `Tempo/Views/Settings/Components/ThemePicker`, `MenuValuePicker`; `RootViewModel.theme`; `RootView` applies `.tint` outermost and sets the window's `tintColor` for UIKit alerts and dialogs (D-101).
- Widgets: `TempoWidgets/Components/View+WidgetTheme` on the Timer, Day, Focus and Now widgets.

### Tests
- `Packages/Core/Tests/CoreTests/Models/ThemeColorTests.swift`: presets by name, eight presets with Blue first and default, custom colors as hex in either case, clamping, anything else is Blue.
- `TempoTests/ViewModels/ThemeTests.swift`: the root shows Blue until a color is chosen; choosing one refreshes the widgets and reaches their snapshot; a picked color becomes its sRGB components; every preset has a name and a color.
- `TempoTests/ViewModels/SettingsViewModelTests.swift`: a custom color survives a restart. `TempoTests/Storage/SwiftDataTaskStoreTests.swift`: round trip. `TempoTests/Storage/StoreFactoryTests.swift` (`versionOneStoreMigratesWithItsData`): a version-1 store opens under the current version with its data and Blue.
- `TempoUITests/SettingsUITests.swift` (`testThemeSwatches`): eight presets and Custom, Blue chosen, then Purple.
- `TempoUITests/ScreenshotTests.swift` (screenshots only): `testThemeOnEveryScreen` (`TEMPO_THEME`), `testThemedWidgetsOnHomeScreen` (run on a simulator without the old `com.applab.tempo` app, whose widgets share the name "Tempo" in the gallery).

### Known gaps
- None for F-27.

## F-28 · Appearance
Status: Built (T-34) · Last updated: 2026-10-11 · T-34

### What it does
Settings › Theme sets whether the app follows the device's light or dark mode, or always uses one of them. The widgets always follow the device.

### Behavior
- **Settings › Theme**, first row: a segmented control with System (the default), Dark and Light, in that order, above the color swatches (D-102). The selected segment is marked, and each is a button named "System", "Dark" or "Light" for VoiceOver. The section's footer is in F-27.
- **Applies at once,** without leaving Settings, to every screen of the app and everything presented over it: sheets, the guide, confirmation dialogs, menus and the system color picker. System follows the device again, including later changes to the device's mode.
- **Doesn't change:** the widgets (Home Screen and Lock Screen), notifications, and the launch screen, which the system draws in the device's mode. With Dark on a light device, the app opens from a light launch screen (D-102).
- The theme color (F-27) is independent: each preset has a light and a dark shade, and a custom color is the same in both.
- A stored appearance that can't be read is System.
- Checked on the iOS 27 simulator: Dark (Teal) on a light simulator and Light (Orange) on a dark simulator on Today, Settings, the editor sheet and the "Delete with history" dialog; Dark on the guide, a Settings menu and the color picker; Light on the color picker; System going back to the device's dark mode.

### Data
`settings.appearance` (SPEC §4.5): `system`, `dark` or `light`. Stores from before T-34 migrate with their data and get `system` (`SchemaV3`, lightweight stage from V2; F-26).

### Implementation (iOS)
- Core: `Packages/Core/Sources/Core/Models/Appearance` (reading the stored string; Codable with the same fallback); `SettingsValue.appearance`.
- Storage: `Shared/Storage/SchemaV3`, `MigrationPlan` (`v2ToV3`); `SwiftDataTaskStore` maps `appearance`.
- Utilities: `Shared/Utilities/Extensions/Appearance+Style` (the windows' `UIUserInterfaceStyle` and the choice's name).
- App: the segmented `Picker` in `Tempo/Views/Settings/SettingsView` (`themeSection`); `RootViewModel.appearance`; `RootView` sets every window's `overrideUserInterfaceStyle` (`.unspecified` for System), which presentations, alerts, menus and the color picker follow. `.preferredColorScheme` isn't used, since it doesn't reliably return to the device's mode (D-102).

### Tests
- `Packages/Core/Tests/CoreTests/Models/AppearanceTests.swift`: System, Dark and Light in that order with System the default; stored by name; anything else is System; decoding an unknown value gives System.
- `TempoTests/ViewModels/AppearanceSettingTests.swift`: the root follows System until a choice is made, then each choice; choosing one keeps the theme color; each choice's window style and name.
- `TempoTests/ViewModels/SettingsViewModelTests.swift`: the appearance survives a restart. `TempoTests/Storage/SwiftDataTaskStoreTests.swift`: round trip and the stored string. `TempoTests/Storage/StoreFactoryTests.swift` (`versionTwoStoreMigratesWithItsData`): a version-2 store keeps its data and custom color and gets System; the version-1 test gets System too.
- `TempoUITests/SettingsUITests.swift` (`testAppearanceChoices`): System chosen at first; Dark makes Settings and the guide dark and Light makes Settings light (measured from screenshots, whatever the simulator's mode); back to System.
- `TempoUITests/ScreenshotTests.swift` (screenshots only): `testThemeOnEveryScreen` with `TEMPO_APPEARANCE` set to Dark or Light.

### Known gaps
- None for F-28.

---

## F-30 · Missed style
Status: Built (T-37, T-40) · Last updated: 2026-10-12 · T-40

### What it does
Settings › Missed tasks chooses how missed tasks look: **Gentle** (the default) says "Not done" in grey, with no badge and no popup; **Strict** is the 1.0 look, "Missed" in red with the badge and the popup. Statuses, the Missed queries and every Stats number are the same in both.

### Behavior
| Where | Strict | Gentle |
|---|---|---|
| Status on rows (Today, Missed, Habit detail's list) | "Missed", red, ✗ icon | "Not done", secondary grey, – icon |
| Ended-part line on Today | "Morning · 2 done · 1 missed" | "Morning · 2 done · 1 not done" |
| Day widget mark | ✗ red | – grey |
| Habit detail week dots | ✗ red | – grey |
| Habit detail calendar | red day, white number | light grey day, normal number |
| Day strip | red dot on today and past days with Missed or Short; spoken "Has missed tasks" | the usual grey dot; spoken "Has tasks not done" |
| Tab title / navigation title | Missed | Not done |
| Tab badge | today's Missed and Short count | none |
| Missed popup | shown | never |
| Earlier count | "14 missed" | "14 not done" |
| Now widget footer | "2 missed today ›", red | "2 not done today ›", grey |
| Recap title | "Today: 2 missed, 1 still open" | "Today: 1 still open, 2 not done" |
| Stats footer | "Most missed: Evening" | "Most often not done: Evening" |
| Habit detail list | "Recent missed days", empty "No missed days" | "Recent days not done", empty "Nothing left undone" |
| Missed › Today, empty | "You haven't missed a task today" | "Nothing left undone today" |
| Missed › Earlier, empty | "Nothing missed before today" | "Nothing undone before today" |
| Filters with no results | "No missed tasks match these filters" | "No tasks match these filters" |

- Short looks the same in both: orange ◐ with "20 of 30 min". The Stats charts color a completion rate, so they don't change (D-120).
- Switching applies at once: the app reloads the settings on every change (`RootViewModel`), widgets read `missed_style` in their snapshot, and the notification rebuild that follows every settings change uses the new recap words.
- Switching from Gentle to Strict marks today's tasks missed so far as seen, so the popup only shows later misses (D-120).
- A stored value the app can't read is Gentle (`MissedStyle(storedValue:)`).

### Data
`settings.missed_style`: `gentle` or `strict` (T-37). The popup's seen list (device-only) is only written in Strict, and on the switch.

### Implementation (iOS)
- `Packages/Core/Sources/Core/Models/MissedStyle.swift` (T-37).
- `Shared/Utilities/Extensions/MissedStyle+Text.swift`: every word, icon and color that depends on the style, shared by the app, the widgets and `NotificationText`.
- `Tempo/Components/StatusLabel`: the status label on Today, Missed and Habit detail rows, which reads the style from the environment.
- `Shared/Utilities/Extensions/EnvironmentValues+MissedStyle.swift`: the `missedStyle` environment value, set by `RootView` from `RootViewModel`.
- Widgets: `DayWidgetContent.missedStyle`, `NowList.missedStyle`, `DayMark.systemImage(_:)`.
- `MissedManager.popupItems` (Strict only) and `markMissedTodaySeen`; `SettingsViewModel.update` calls it on the switch to Strict.
- UI tests launch in Gentle; `-ui-testing-strict` (`UITestApp.launch(strict:)`, and every popup test) chooses Strict.

### Tests
- `TempoTests/ViewModels/MissedStyleBehaviorTests.swift`: statuses, Missed queries and Stats identical in both styles; widgets follow the stored style; the words and marks.
- `TempoTests/Managers/MissedManagerTests.swift`: no popup in Gentle; switching to Strict marks today's misses seen and a later miss still shows.
- `TempoTests/Notifications/NotificationTextTests.swift`: the recap in both styles; nothing else changes.
- `TempoUITests/MissedUITests.swift` (`testGentleStyleWording`, and the Strict tests), `SettingsUITests.testMissedStyleChoice`, and the other UI tests, which now expect the Gentle tab name.

### Known gaps
- None for F-30.
