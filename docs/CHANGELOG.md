# Changelog

Every change to `docs/SPEC.md` or `docs/platform/*.md`, newest first. Code-only changes that don't alter behavior aren't listed here; they're recorded in commits and in `DOCUMENTATION.md`.

## Entry format

```markdown
## YYYY-MM-DD · Short title
- Changed: F-xx — what changed and why (D-0xx if a decision is involved)
- Added: T-xx — new task
- Removed: F-xx — reason (the item stays in the spec, marked Removed)
- Platform: ios.md §n — what changed
```

---

## 2026-10-12 · Same timer controls everywhere (T-44)
- Changed: F-06 — every place that shows the timer can pause and resume it; the Timer widget's Done saves a habit timer without opening the app (D-111, superseding D-022).
- Changed: F-17, F-18, F-21 — the Timer widget's habit states have Pause/Resume and Done; the Now widget's generic timer line, "Timer · 05:12", has Pause/Resume and Done.
- Changed: T-23, T-24 acceptance — the display-only items now expect the controls.
- Platform: ios.md §8, §15 — the Timer widget reuses `FinishHabitTimerIntent`; the Now widget's line reuses the pause, resume and generic finish intents.

## 2026-10-12 · Snooze reminders (T-43)
- Changed: F-07 — fixed-time and ending-soon notifications can be snoozed for 15 minutes or an hour, when that lands at least 5 minutes before the part ends; the snooze is rebuilt from current data and replaces an earlier one (D-110, D-122).
- Changed: §2.1, §2.2 — snoozing is in v1.
- Changed: §5.9 — snoozed ids and the snooze options on fixed-time and ending-soon items.
- Changed: §7 — the snooze choices.
- Platform: ios.md §10, §15 — the snooze categories, `SnoozeRequest`, and the delegate's background handling.

## 2026-10-12 · Part summaries per part (T-42)
- Changed: F-07, F-16, §5.9 — each part's summary has its own switch; only Morning's is on by default (D-109, superseding D-016).
- Changed: §7 — the summaries' defaults.
- Platform: ios.md §15 — Settings' four switches; the planner checks `partStartSummaries`.

## 2026-10-12 · Correction window for yesterday (T-41)
- Added: §5.11 — Editable days: yesterday can be corrected (complete, undo, log time, delete time entries) until today's Afternoon start (D-108, D-121).
- Changed: §1.2 — honest records: today until midnight, yesterday until the afternoon starts, earlier days final.
- Changed: §1.3 — glossary entries for the correction window, and for the missed style (left out of T-40).
- Changed: §2.1 — the correction window is in v1.
- Changed: F-04 — a "Yesterday, before today's Afternoon starts" row; Past days becomes "Earlier days, and yesterday after the window".
- Changed: F-05, F-06, F-08, F-10, F-12, F-13, §5.4 — Log time, deleting entries, the Missed tab's Yesterday group, Today's line and actions for yesterday, Mark not done and Habit detail's entries follow §5.11.
- Changed: §6, §7 — the window's edge cases and limit.
- Changed: T-05, T-06 acceptance — past-day items allow yesterday during the window.
- Platform: ios.md §15 — `EditWindow`, `TaskManager.editWindow()`, `logTime(day:)`, `LogTimeRequest.day`.

## 2026-10-12 · Missed style (T-40)
- Added: F-30 — Missed style: Gentle (default, "Not done", grey, no badge or popup) or Strict (the 1.0 look) (D-107, D-120).
- Changed: §2.1 — missed tracking is shown Gentle or Strict.
- Changed: F-07, F-08, F-09, F-10, F-13, F-14, F-19, F-21, F-24 — the quoted missed strings are marked "(Strict; Gentle in F-30)"; the popup and the badge are Strict only.
- Changed: F-16 — a Missed tasks setting under Parts of the day.
- Changed: F-27 — missed is red in Strict and grey in Gentle.
- Changed: §7 — the missed style's default.
- Platform: ios.md §15 — `MissedStyle+Text`, the `missedStyle` environment value, `-ui-testing-strict`.

## 2026-10-12 · "Afternoon" on screen (T-39)
- Changed: F-02 — the part that starts at `noon_start` is called Afternoon on screen; stored values and ids keep `noon` (D-106). The line "'Before night' in everyday speech means Evening" is removed.
- Changed: §1.1, §1.3, F-04, F-07, F-08, F-10, F-15, F-16, F-19, F-20, F-22, F-24, §6, §7 — every user-facing "Noon" is now "Afternoon"; Afternoon's empty text is "Nothing this afternoon" / "Nothing in the afternoon".
- Changed: T-05, T-07 acceptance — "Noon task" reads "Afternoon task".
- Platform: ios.md §15 — `DayPart.title` and both string catalogs.

## 2026-10-12 · Notes on tasks (T-38)
- Changed: §2.1, §2.2 — notes on tasks are in v1.
- Changed: F-01 — every task can have notes (up to 1,000 characters), edited wherever the title can, never shown in widgets, on the Lock Screen or in notifications (D-105, D-119).
- Changed: F-04 — Move to tomorrow's copy keeps the notes.
- Changed: F-10, F-11 — rows show a small notes icon when a task has notes.
- Changed: F-13 — the header shows the notes.
- Changed: F-15 — a Notes field after the title, with its message.
- Changed: §7 — the notes limit.
- Platform: ios.md §15 — `NotesIndicator`, the editor's notes field and `TaskManager.setNotes`.

## 2026-10-12 · Data model changes (T-37)
- Changed: §4.1 — `tasks` gains `notes` (optional, up to 1,000 characters after trimming; empty is stored as no value).
- Changed: §4.5 — `notify_part_start` is replaced by `notify_part_start_morning` (true), `_noon`, `_evening` and `_night` (false); `missed_style` (`"gentle"`) is added.
- Changed: §4.6, F-26 — device-only state gains Snoozes, Add a widget card closed and the Pro entitlement, none of which sync.
- Platform: ios.md §6, §15 — `SchemaV4` with a lightweight stage from V3; the new `DeviceState` keys.

## 2026-10-12 · Minimum system version iOS 18 (T-36)
- Platform: ios.md §1, §3, §5, §6, §7, §15 — the deployment target is iOS 18.0 for every target and the `Core` package; APIs from iOS 26 on need `#available` with a fallback; D-044's storage approach stays (D-104, superseding D-052).
- Process: CLAUDE.md — the definition of done and the API rule name iOS 18.
- No changes to SPEC.md: it never names a platform version.

## 2026-10-12 · Spec catches up with the build (T-35)
- Changed: F-06 — the task picker lists duration habits live on the timer's day (the previous day after midnight), can't be swiped away, keeps the time while Add a duration task is open, and leaves out the current habit with Cancel for Change task (D-084, D-103).
- Changed: F-20 — "All N tasks done" only when every one of today's tasks is done; "Then:" shows only the next title (D-091, D-103).
- Changed: F-21 — at most 8 rows below the header (D-090, D-103).
- Changed: F-22 — a duration habit's rows follow its timing, "All N tasks done" follows F-20, the inline widget hides its whole line while locked with Hide task names on, and the gallery name is Next task (D-092, D-103).
- Process: CLAUDE.md — an Agent decision that changes behavior updates SPEC and CHANGELOG in the same change (D-103).

## 2026-10-12 · Phase H planned (1.1)
- Added: T-35–T-53 — Phase H · Pre-launch changes, from `docs/CHANGE-SPEC-1.1.md` (C-01–C-16), in SPEC §8. T-52 (final name) is blocked and listed last. Each task copies its change into SPEC before it's built.
- No other changes to SPEC.md yet.

## 2026-10-11 · Appearance
- Added: F-28 — Appearance: System, Dark or Light for the app, in Settings › Theme.
- Changed: §2.1 — the appearance choice is in v1.
- Changed: F-16 — the Theme section holds the appearance and the color.
- Changed: F-17 — widgets follow the system's light or dark mode, whatever the app's appearance.
- Changed: §4.5 — the `settings` table gains `appearance` (default `"system"`).
- Changed: §7 — the appearance's default.
- Added: T-34 — Appearance, in Phase G.
- Platform: ios.md §3, §6, §9, §12, §15 — `SchemaV3` with a lightweight migration from V2, `Appearance`, the window's `overrideUserInterfaceStyle` (D-102).

## 2026-10-11 · Theme color details (T-33)
- Platform: ios.md §3, §12 — Settings' menus use `MenuValuePicker`, because a menu-style `Picker` ignores the tint (D-101).
- No changes to SPEC.md.

## 2026-10-10 · Theme color
- Added: F-27 — Theme color: eight presets or a custom color, applied to the whole app and to the Home Screen widgets' accents.
- Changed: §2.1 — the theme color is in v1.
- Changed: F-16 — Settings has a Theme section.
- Changed: F-17 — widgets use the theme color for their accents, except in the tinted and clear styles and on the Lock Screen.
- Changed: §4.5 — the `settings` table gains `tint_color` (default `"blue"`).
- Changed: §7 — the theme color's default.
- Added: T-33 — Theme color, in a new Phase G.
- Platform: ios.md §3, §6, §9, §12, §15 — `SchemaV2` with a lightweight migration, `ThemeColor`, the root and widget `.tint`, the Theme picker.

## 2026-10-10 · New developer team and identifiers
- Platform: ios.md §2, §6, §10 — bundle IDs are `com.akumatech.tempo` (app) and `com.akumatech.tempo.widgets`, the App Group is `group.akumatech.tempo`, and the background refresh task is `com.akumatech.tempo.refresh`, after the move to team `L9B6N63T2Q`. The rename note lists everything that has to change together.
- No changes to SPEC.md.

## 2026-10-10 · Notification delegate (T-32)
- Platform: ios.md §10 — the notification delegate uses the completion-handler callbacks on the main actor; the async ones crashed the app when a notification was tapped.
- No changes to SPEC.md.

## 2026-10-10 · Accessibility notes (T-31)
- Platform: ios.md §9 — main widget buttons switch to a bordered style outside full color.
- Platform: ios.md §12 — how haptics are triggered, and the large-text layouts (D-097).
- Platform: ios.md §15 — the accessibility audit test and how to set text size, appearance and widget styles for screenshots.
- No changes to SPEC.md.

## 2026-10-10 · Readable width on iPad (T-30)
- Platform: ios.md §12 — lists and forms keep to the readable width with content margins (`readableScrollContent()`), fixed content with `readableWidth()`; sheets keep the system form-sheet size (D-096).
- Platform: ios.md §15 — how to test narrow windows and take landscape screenshots on iPad.
- No changes to SPEC.md.

## 2026-10-10 · Links on first launch (T-29)
- Platform: ios.md §11 — a link or pending open action that arrives before the first-launch guide is finished waits for the guide to close (D-095).
- No changes to SPEC.md.

## 2026-10-10 · First-launch guide storage (T-28)
- Platform: ios.md §3, §6, §12 — "guide completed" is kept in `DeviceState` (App Group defaults) instead of `@AppStorage`, and the guide is presented through `NavigationRouter.guide` in first-launch or How to use mode (D-094).
- No changes to SPEC.md.

## 2026-10-10 · Lock Screen widget testing (T-27)
- Platform: ios.md §13 — Lock Screen widgets are checked through the Lock Screen editor on the iOS 26.5 simulator (iOS 27.0's can't open it); hidden titles can only be seen locked on a device, and a preview shows them redacted.
- No changes to SPEC.md.

## 2026-10-07 · Now widget checkboxes (T-24)
- Platform: ios.md §8, §9 — the Now widget's checkboxes are `Button(intent:)` with an explicit target state instead of `Toggle(isOn:intent:)`, which didn't complete on the iOS 27 simulator (D-090).
- No changes to SPEC.md.

## 2026-10-07 · Timer widget details (T-23)
- Platform: ios.md §3 — the T-01 `Widgets/Placeholder/` folder is gone.
- Platform: ios.md §13 — screenshot tests can add a widget to the Home Screen through SpringBoard.
- No changes to SPEC.md.

## 2026-10-07 · Widget foundation details (T-22)
- Platform: ios.md §3 — `WidgetSnapshot`, `SnapshotLoader` and the new `WidgetTimelinePlan` live in `Shared/Widgets/`, so app tests can test them; `TempoWidgets/Provider/` keeps `TodayTimelineProvider` and `TodayEntry` (D-089).
- Platform: ios.md §8 — intents use `IntentEnvironment` and `refreshNowAndWait()`; `ToggleCompletionIntent` is a `SetValueIntent`.
- Platform: ios.md §9 — the provider sample matches the code.
- No changes to SPEC.md.

## 2026-10-07 · Notification details (T-21)
- Platform: ios.md §10 — the delegate holds early responses; the planner returns content and `NotificationText` writes the words.
- Platform: ios.md §13 — `-ui-testing-finished-timer` (added in T-20).
- No changes to SPEC.md. D-087 and D-088 fill gaps in F-07: the Morning summary's wording and count, how the recap classes tasks, and clearing pending notifications when permission is off.

## 2026-10-07 · Missed popup details (T-17)
- Platform: ios.md §13 — `-ui-testing-no-popup` keeps the missed popup out of UI tests that aren't about it.
- No changes to SPEC.md. D-082: swiping the popup away counts as seen, like its buttons.

## 2026-10-07 · Today screen details (T-12)
- Platform: ios.md §13 — `-ui-testing-sample` starts UI tests with sample data.
- No changes to SPEC.md. D-073 to D-077 fill gaps in F-05, F-10 and F-24: Log time's starting value, empty-part wording, folding ended parts, red dots only for today and past days, and the layout of swipe actions.

## 2026-10-07 · Task editor details (T-11)
- Platform: ios.md §13 — UI tests also pass `-ui-testing-timezone`, so fixed times mean the same on any Mac.
- No changes to SPEC.md. D-068 to D-072 fill gaps in F-15 and F-03: editor defaults and when the title message appears, ended parts for edits that apply today, Start again after its part has ended, read-only tasks, and End habit offered next to Delete with history.

## 2026-10-07 · Settings details (T-10)
- Platform: ios.md §13 — `ScreenshotTests` in `TempoUITests`, run only with `TEST_RUNNER_TEMPO_SCREENSHOTS`.
- No changes to SPEC.md. D-066 (the recap follows Night) and D-067 (asking for permission from Settings) fill gaps in F-16.

## 2026-10-07 · UI tests and navigation details (T-09)
- Platform: ios.md §3 — new `TempoUITests` target in the `Tempo` scheme (D-064).
- Platform: ios.md §13 — UI tests, and the `-ui-testing` / `-ui-testing-now` launch arguments.
- Platform: ios.md §15 T-09 — Settings and History push onto their tab's stack; the editor, timer screen and task picker are sheets (D-063).
- No changes to SPEC.md.

## 2026-10-07 · Atomic store writes (T-04)
- Platform: ios.md §4 — `TaskStore` gains `write(_:)`, which saves several rows in one context so a task and its schedule, or everything deleted with a habit, land together.
- No changes to SPEC.md. D-058 and D-059 record how F-03's length and start-day edits are applied.

## 2026-10-07 · Storage details (T-03)
- Platform: ios.md §1 — the app, widget and test targets enable `InferSendableFromCaptures`, so SwiftData key paths don't warn under complete concurrency checking (D-055).
- Platform: ios.md §4 — `Clock` also provides the `Calendar` that rules run in (D-054). The `TaskStore` sample shows the real shape: `loadAll()`, upserting `save` that returns the stored copy, and `softDelete…(id:)`.
- No changes to SPEC.md.

## 2026-10-07 · Test runs use the latest installed iOS simulator
- Platform: ios.md §5 — the required test run before closing a task is on the latest iOS simulator installed (currently iOS 27.0), not iOS 17. Xcode 27 can't install iOS 17 or 18 runtimes. The deployment target stays iOS 17.0, and the iOS 18+ API ban still applies (D-052).
- Platform: ios.md §13 — the `Core` simulator run and the manual QA checklist's full pass now use the latest installed iOS.
- No changes to SPEC.md.

## 2026-10-07 · Project skeleton details (T-01)
- Platform: ios.md §1 — default actor isolation stays `nonisolated`, and Approachable Concurrency is off (D-047).
- Platform: ios.md §3 — the tree now lists `.gitignore`, `Tempo.xcodeproj`, each target's `Info.plist` and entitlements, `TempoWidgets/Resources/` (D-046) and the temporary `Widgets/Placeholder/`. New folder rule 7 covers `.gitkeep` files (D-048).
- Platform: ios.md §13 — how to run the `Core` tests on a simulator (D-050).
- No changes to SPEC.md. The docs moved from `TaskWidget/DOCS/` to `docs/` and `docs/platform/`, where `CLAUDE.md` expects them.

## 2026-10-06 · Spec v1.0
- Added: the initial spec from the design discussion: features F-01–F-26, rules §5, and build plan T-01–T-32.
- Added: `docs/platform/ios.md`, `docs/DOCUMENTATION.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` (D-001–D-045) and `CLAUDE.md`.
