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

Status: Not built · Last updated: —

_Nothing has been built yet. Once T-01 is done, summarize here the app's current state: targets, folders, and which features are live._

---

## F-01 · Task types
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-01._

## F-02 · Timing and parts of the day
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-02._

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
Status: Not built · Last updated: —

_Not built yet. Intended behavior: SPEC F-26._
