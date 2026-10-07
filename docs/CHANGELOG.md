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
