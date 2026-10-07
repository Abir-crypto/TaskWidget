# Progress

**Current task:** T-01 · Project skeleton

Legend: ⬜ To do · 🔄 In progress · ✅ Done · ⛔ Blocked

Update this file when you start a task (🔄), when you finish one (✅, with the date and notes), and whenever you're blocked (⛔, with a reason under Blocked). Keep **Current task** pointing to the first task that isn't ✅.

## Tasks

| Task | Title | Phase | Status | Finished | Notes |
|---|---|---|---|---|---|
| T-01 | Project skeleton | A · Foundation | ⛔ |  | All four acceptance items pass on iOS 26.5 and 27.0 (iPhone 17, iPad Pro 11-inch). Widget registration was checked with `pluginkit`. Only the required iOS 17 run is missing; see Blocked. |
| T-02 | Days, weekdays and parts of the day | A · Foundation | ⬜ |  |  |
| T-03 | Data model and storage | A · Foundation | ⬜ |  |  |
| T-04 | Occurrences and schedule history | A · Foundation | ⬜ |  |  |
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

- **T-01 · iOS 17 test run (2026-10-07).** No iOS 17 simulator runtime is installed; only iOS 26.5 and 27.0 are. `CLAUDE.md` requires every task to be tested on iOS 17. Everything else in T-01 is done and committed. To unblock: install an iOS 17 runtime, for example with `xcodebuild -downloadPlatform iOS -buildVersion 17.5` (several GB), then run the `Tempo` and `Core` test commands with `OS=17.x`. Waiting for the owner to decide.

## Session log

Add one line per work session, newest first: the date, what was done, and anything the next session needs to know.

- 2026-10-07 — T-01 skeleton built: git repo, docs moved to `docs/`, `Tempo.xcodeproj` (app, widget extension, tests), `Packages/Core`, the ios.md §3 folder tree, App Group, URL scheme, background fetch, string catalogs and `.swift-format`. Tests pass on iOS 26.5 and 27.0. Blocked on the iOS 17 runtime. The Mac's `xcode-select` points to the Command Line Tools, so `xcodebuild` needs `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` until it's switched.
- 2026-10-06 — Spec v1.0 and supporting docs written. No code yet. Next: T-01.
