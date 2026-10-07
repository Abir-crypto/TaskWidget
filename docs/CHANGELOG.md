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
