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
Status: Partly built (T-04) · Last updated: 2026-10-07 · T-04

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
- Creating a task in a part of today that has already ended isn't blocked yet (T-11, D-035).

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
Status: Partly built (T-06) · Last updated: 2026-10-07 · T-06

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

### Tests
- `Packages/Core/Tests/CoreTests/Duration/DurationMathTests.swift`: rounding, summing, the §5.5 example, a mid-week target change, mid-week weekday change, start and last days, unscheduled days, region week start, Log time steps.
- `TempoTests/Managers/TimeLoggingTests.swift`: Log time on today and unscheduled days, refused on future and ended habits, steps, type, deleting today's but not past entries.

### Known gaps
- The Log time sheet (T-12), today's entries in Habit detail (T-15), and the timer's entries (T-19).

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
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-24._

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
