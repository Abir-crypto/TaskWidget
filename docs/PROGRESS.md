# Progress

**Current task:** T-05 · Status and the daily cycle

Legend: ⬜ To do · 🔄 In progress · ✅ Done · ⛔ Blocked

Update this file when you start a task (🔄), when you finish one (✅, with the date and notes), and whenever you're blocked (⛔, with a reason under Blocked). Keep **Current task** pointing to the first task that isn't ✅.

## Tasks

| Task | Title | Phase | Status | Finished | Notes |
|---|---|---|---|---|---|
| T-01 | Project skeleton | A · Foundation | ✅ | 2026-10-07 | All four acceptance items pass on iOS 26.5 and 27.0 (iPhone 17, iPad Pro 11-inch). Widget registration was checked with `pluginkit`. Unblocked by D-052: the required run is now on the latest installed simulator (iOS 27.0), and the iOS 17.0 deployment target stays. Re-run on iOS 27.0: `TempoTests` 5/5, `Core` 1/1 on the simulator and with `swift test`. |
| T-02 | Days, weekdays and parts of the day | A · Foundation | ✅ | 2026-10-07 | `Core/Calendar`: `DayKey`, `LocalTime`, `Weekday`, `Weekdays`, `DayPart`, `PartSettings`. 33 Core tests pass with `swift test` and on the iOS 27.0 simulator; `TempoTests` pass. Placeholders `CorePlaceholder` and its test removed. D-053 (daylight-saving gap). |
| T-03 | Data model and storage | A · Foundation | ✅ | 2026-10-07 | Core value types, `SchemaV1` records, `StoreFactory`, `TaskStore`/`SwiftDataTaskStore`, `DeviceState`, `SettingsManager`, `RefreshManager` (widgets only until T-21), `Clock`. 37 `TempoTests` and 33 Core tests pass on iOS 27.0. Cross-process reads tested with two containers on one App Group file; the app launch was checked to write the default settings row to the real store. D-054–D-057. |
| T-04 | Occurrences and schedule history | A · Foundation | ✅ | 2026-10-07 | `Core/Schedule`: `ScheduleEngine`, `ScheduleHistory`, `TaskRules`; `Occurrence`; `TaskValue.lastDay`. `TaskManager` (create, schedule edits per §4.2, rename, length, start day, End habit, Start again, deletes) and atomic `TaskStore.write`. 58 Core tests (Mac and iOS 27.0) and 56 `TempoTests` pass. D-058, D-059. |
| T-05 | Status and the daily cycle | A · Foundation | ⬜ |  |  |
| T-06 | Duration math | A · Foundation | ⬜ |  |  |
| T-07 | Next-task rule and missed queries | A · Foundation | ⬜ |  |  |
| T-08 | Stats calculations | A · Foundation | ⬜ |  |  |
| T-09 | App structure and navigation | B · App screens | ⬜ |  |  |
| T-10 | Settings | B · App screens | ⬜ |  |  |
| T-11 | Task editor | B · App screens | ⬜ |  |  |
| T-12 | Today screen and Log time | B · App screens | ⬜ |  |  |
| T-13 | Tasks tab | B · App screens | ⬜ |  |  |
| T-14 | History | B · App screens | ⬜ |  |  |
| T-15 | Habit detail | B · App screens | ⬜ |  |  |
| T-16 | Missed tab | B · App screens | ⬜ |  |  |
| T-17 | Missed popup | B · App screens | ⬜ |  |  |
| T-18 | Stats screen | B · App screens | ⬜ |  |  |
| T-19 | Timer engine | C · Timer | ⬜ |  |  |
| T-20 | Timer in the app | C · Timer | ⬜ |  |  |
| T-21 | Notifications | D · Notifications | ⬜ |  |  |
| T-22 | Widget foundation | E · Widgets | ⬜ |  |  |
| T-23 | Timer widget | E · Widgets | ⬜ |  |  |
| T-24 | Now widget | E · Widgets | ⬜ |  |  |
| T-25 | Day widget | E · Widgets | ⬜ |  |  |
| T-26 | Focus widget | E · Widgets | ⬜ |  |  |
| T-27 | Lock Screen widgets | E · Widgets | ⬜ |  |  |
| T-28 | First-launch guide | F · Finish | ⬜ |  |  |
| T-29 | Empty states check | F · Finish | ⬜ |  |  |
| T-30 | iPad | F · Finish | ⬜ |  |  |
| T-31 | Accessibility and polish | F · Finish | ⬜ |  |  |
| T-32 | Final verification | F · Finish | ⬜ |  |  |

## Blocked

Nothing is blocked.

- ~~**T-01 · iOS 17 test run (2026-10-07).**~~ Resolved 2026-10-07: Xcode 27 can't download iOS 17 or 18 runtimes (`xcodebuild -downloadPlatform` reports them unavailable). The owner chose to test on the latest installed simulator and keep the iOS 17.0 deployment target (D-052).

## Session log

Add one line per work session, newest first: the date, what was done, and anything the next session needs to know.

- 2026-10-07 — T-01 unblocked (D-052): tests now run on the latest installed iOS simulator (iOS 27.0, iPhone 17); the deployment target stays iOS 17.0. `xcode-select` still points to the Command Line Tools, so keep prefixing `xcodebuild` and `xcrun` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. String catalogs: after a simulator build, `xcrun xcstringstool sync <catalog> --stringsdata …` merges the extracted strings (the build doesn't write them back on the command line).
- 2026-10-07 — T-01 skeleton built: git repo, docs moved to `docs/`, `Tempo.xcodeproj` (app, widget extension, tests), `Packages/Core`, the ios.md §3 folder tree, App Group, URL scheme, background fetch, string catalogs and `.swift-format`. Tests pass on iOS 26.5 and 27.0. Blocked on the iOS 17 runtime. The Mac's `xcode-select` points to the Command Line Tools, so `xcodebuild` needs `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` until it's switched.
- 2026-10-06 — Spec v1.0 and supporting docs written. No code yet. Next: T-01.
