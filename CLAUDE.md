# CLAUDE.md

Tempo (working title) is an iOS and iPadOS 17+ to-do app organized by the time of day, with widgets at its core. These are the rules for working on this repo.

## Documents

Read them when a task needs them. Don't load every document every session.

| File | Use it for |
|---|---|
| `docs/SPEC.md` | **What** to build. Platform-neutral. Features `F-xx`, rules §5, build plan §8 (`T-xx`). |
| `docs/platform/ios.md` | **How** to build it on iOS: architecture, storage, widgets, notifications, task notes (§15). |
| `docs/PROGRESS.md` | Which task is next, and the status of every task. |
| `docs/DOCUMENTATION.md` | What the app does **right now**, as built. You keep it up to date. |
| `docs/DECISIONS.md` | Why things are the way they are. Add an entry for every judgment call. |
| `docs/CHANGELOG.md` | Every change to the spec, with its date. |

## Workflow

1. **Work on one task at a time, in order.** The current task is the first one in `docs/PROGRESS.md` that isn't ✅.
2. **Before writing code,** read:
   - the task in `docs/SPEC.md` §8;
   - every feature and rule it lists under "Implements";
   - its notes in `docs/platform/ios.md` §15.
3. **When you start a task,** mark it 🔄 in `PROGRESS.md`.
4. **A task is done** only when all of these hold:
   - the build passes with no new warnings;
   - all tests pass, run on an iOS 17 simulator and on the latest one;
   - every acceptance item is checked;
   - `docs/DOCUMENTATION.md` is updated;
   - `docs/PROGRESS.md` is updated, with ✅, the date and notes.
5. **When a task is done,** commit, summarize what you did and any decisions you made, then **stop and wait**. Don't start the next task unless asked.
6. **If you're blocked,** mark the task ⛔ in `PROGRESS.md`, explain why under "Blocked", and ask.

## Changing the app: spec first

If a request adds, changes or removes behavior, however small, follow this order:

1. Update the affected sections of `docs/SPEC.md` first, and `docs/platform/ios.md` if the iOS approach changes.
2. Add a dated entry to `docs/CHANGELOG.md`.
3. Add or change tasks in SPEC §8 and in `PROGRESS.md`. New tasks get the next free `T-` number and go where they belong in the order.
4. Only then change the code.
5. Update `docs/DOCUMENTATION.md`.

**Code that disagrees with the spec is a bug,** whichever side is wrong. If you notice a mismatch, raise it rather than quietly picking one.

**IDs never change.** Never renumber `F-`, `T-` or `D-` IDs. A removed item stays in place, marked `Removed (date): reason`.

**Keep SPEC.md platform-neutral.** No framework or API names; those belong in `docs/platform/ios.md`.

## Documentation rule

After **every** change, update the affected feature's section in `docs/DOCUMENTATION.md` in the same commit, including its `Last updated` line.

- This applies to any change in behavior, UI, copy, defaults, data, notifications, widgets, or which files implement a feature.
- A pure refactor that changes none of those doesn't need an entry.
- A task isn't done until `DOCUMENTATION.md` matches the code.

## Decisions

- **When the spec is silent or ambiguous,** choose the simplest option consistent with SPEC §1.2.
  - Record it in `docs/DECISIONS.md` with the next `D-` number, marked "Agent".
  - Mention it in your summary.
- **If it's a real product question with trade-offs,** ask instead of deciding.

## Architecture and code (full detail in `docs/platform/ios.md`)

- **Layers:** SwiftUI views → `@Observable @MainActor` view models → managers in `Shared/Managers/` → pure rules in `Packages/Core`. Widgets and App Intents use the same managers.
- **Storage:**
  - Storage is the single source of truth.
  - Every write goes through a manager, and `RefreshManager.afterChange()` runs after every write.
  - No `@Query`. Use a fresh `ModelContext` for each read or write.
  - `@Model` objects never leave `Shared/Storage/`.
- **Time:** "now" always comes from `Clock`. `Core` never calls `Date()` or `Calendar.current`.
- **Loading:** load in `.task`, never in `onAppear`.
- **iOS 17:** no APIs introduced in iOS 18 or later (list in ios.md §5).
- **Safety:** no force unwraps and no `try!` outside tests. Use specific `Error` types and log with `os.Logger`.
- **Text and accessibility:** all user-facing text goes in `Localizable.xcstrings`, and every interactive element has an accessibility label.
- **Previews:** every view, and every widget state, has a `#Preview`.
- **Tests:** written first for `Core`, with a fixed calendar and clock (ios.md §13).
- **Formatting:** run `swift-format` before committing.

## Why the storage rules exist

- The app and the widget extension (through its App Intents) both write to one data store in the App Group. On iOS 17, a long-lived `ModelContext` or `@Query` doesn't see the other process's writes. That's why there's no `@Query` and why every read or write uses a fresh context.
- Statuses (missed, done, …) are calculated from `Clock`, never stored (D-012). Don't add a stored status field or a job that updates statuses at part boundaries.

## File organization

- Each screen has its own folder: `Tempo/Views/<Screen>/` holds `<Screen>View.swift` and `<Screen>ViewModel.swift`.
- A subview used by one screen goes in that screen's `Components/` folder. Once a second screen uses it, it moves to `Tempo/Components/<Name>/`.
- Business logic goes in `Shared/Managers/` (one manager per area). Rules go in `Packages/Core`. Generic helpers go in `Shared/Utilities/`.
- Each widget has its own folder: `TempoWidgets/Widgets/<Widget>/`.
- Each file holds one type, and the file name matches the type name.

## Don't

- Build anything that isn't in the spec. Add it to the spec first.
- Add third-party dependencies.
- Edit SPEC.md or ios.md without a CHANGELOG entry.
- Mark a task done with failing tests or unchecked acceptance items.
- Start the next task without being asked.

## Commands

```bash
swift test --package-path Packages/Core                                   # Core tests
swift test --package-path Packages/Core --filter <SuiteOrTestName>       # one Core test
xcrun simctl list devices available                                       # find a simulator name
xcodebuild -scheme Tempo -destination 'platform=iOS Simulator,name=<iPhone>' build test
xcodebuild -scheme Tempo -destination 'platform=iOS Simulator,name=<iPhone>,OS=17.<x>' test   # the required iOS 17 run
xcodebuild -scheme Tempo -destination 'platform=iOS Simulator,name=<iPhone>' test -only-testing:TempoTests/<Suite>/<testName>   # one app test
swift format --in-place --recursive Tempo TempoWidgets Shared Packages    # formatting
```
