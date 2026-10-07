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

## 2026-10-07 · Project skeleton details (T-01)
- Platform: ios.md §1 — default actor isolation stays `nonisolated`, and Approachable Concurrency is off (D-047).
- Platform: ios.md §3 — the tree now lists `.gitignore`, `Tempo.xcodeproj`, each target's `Info.plist` and entitlements, `TempoWidgets/Resources/` (D-046) and the temporary `Widgets/Placeholder/`. New folder rule 7 covers `.gitkeep` files (D-048).
- Platform: ios.md §13 — how to run the `Core` tests on a simulator (D-050).
- No changes to SPEC.md. The docs moved from `TaskWidget/DOCS/` to `docs/` and `docs/platform/`, where `CLAUDE.md` expects them.

## 2026-10-06 · Spec v1.0
- Added: the initial spec from the design discussion: features F-01–F-26, rules §5, and build plan T-01–T-32.
- Added: `docs/platform/ios.md`, `docs/DOCUMENTATION.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` (D-001–D-045) and `CLAUDE.md`.
