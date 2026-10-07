# iOS Platform Guide

> How `docs/SPEC.md` is built on iOS and iPadOS. It uses the same feature (`F-xx`) and task (`T-xx`) IDs. **SPEC.md decides behavior.** If this file disagrees with it about what the app does, SPEC.md wins and this file gets fixed.

---

## 1. Stack

- **OS:** iOS and iPadOS 17.0 or later, as one universal app.
- **Frameworks:** Swift, SwiftUI, SwiftData (on the device only), WidgetKit, App Intents, UserNotifications, Swift Charts, and background refresh through SwiftUI's `.backgroundTask`.
- **No third-party dependencies.**
- **Xcode:** latest stable (16 or later). The project uses folder-synchronized groups, so files created on disk show up in Xcode automatically, without editing the project file.
- **Swift language mode:**
  - The `Core` package uses Swift 6.
  - The app and widget targets use Swift 5 mode, with Strict Concurrency Checking set to Complete (as warnings). SwiftData types aren't `Sendable`, and Swift 6 mode there would mean fighting the compiler.
  - Default actor isolation stays `nonisolated`, and Approachable Concurrency is off (Xcode 26+ templates turn both on). `@MainActor` is written explicitly where it's needed, as in §4.
  - The app, widget and test targets turn on the upcoming feature `InferSendableFromCaptures` (`SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES = YES`, on by default in Swift 6). Without it, every key path in a SwiftData `#Predicate` or `SortDescriptor` warns under complete checking (D-055).

---

## 2. Targets, identifiers and capabilities

| Item | Value |
|---|---|
| App target / bundle ID | `Tempo` / `com.applab.tempo` |
| Widget extension / bundle ID | `TempoWidgets` / `com.applab.tempo.widgets` |
| Logic package | `Packages/Core` (library `Core`) |
| App Group | `group.com.applab.tempo` |
| URL scheme | `tempo` |
| Background refresh task | `com.applab.tempo.refresh` |
| Notification category | `TIMER_ALERT`, with actions `STOP` and `KEEP_GOING` |

**Capabilities**
- **App:** App Groups, plus Background Modes → Background fetch.
- **Widget extension:** App Groups.
- **No iCloud or CloudKit.** v1 has no sync (SPEC F-26).

**App `Info.plist`**
- `BGTaskSchedulerPermittedIdentifiers` = `["com.applab.tempo.refresh"]`.
- A URL type with the scheme `tempo`.
- Orientations: iPhone portrait only; iPad all four.

To rename the app, replace `Tempo`, `com.applab.tempo` and `tempo://` everywhere in one pass.

---

## 3. Project structure

```
Tempo/
├── CLAUDE.md
├── .swift-format
├── .gitignore
├── Tempo.xcodeproj                       # shared scheme: Tempo (app + TempoTests + TempoUITests)
├── docs/                                 # SPEC, DOCUMENTATION, PROGRESS, DECISIONS, CHANGELOG, platform/
├── Packages/
│   └── Core/                             # pure Swift: no SwiftUI, SwiftData, WidgetKit or UIKit
│       ├── Package.swift
│       ├── Sources/Core/
│       │   ├── Calendar/                 # DayKey, Weekdays, DayPart, PartSettings
│       │   ├── Models/                   # value types: TaskValue, ScheduleValue, Occurrence, Status, …
│       │   ├── Schedule/                 # ScheduleEngine (occurrences, schedule history)
│       │   ├── Status/                   # StatusRules, Editability
│       │   ├── Duration/                 # DurationMath
│       │   ├── NextTask/                 # NextTaskRule
│       │   ├── Missed/                   # MissedQueries, MissedFilter
│       │   ├── Stats/                    # StatsCalculator, StatsSnapshot
│       │   ├── Reminders/                # ReminderPlanner
│       │   ├── Timeline/                 # TimelinePlanner (widget update moments)
│       │   └── Timer/                    # TimerState, TimerRules
│       └── Tests/CoreTests/
├── Shared/                               # target membership: Tempo AND TempoWidgets
│   ├── Managers/
│   │   ├── TaskManager.swift             # tasks, schedules, completions, time entries; enforces F-04
│   │   ├── TimerManager.swift            # the one timer, stored on the device
│   │   ├── ReminderManager.swift         # turns ReminderPlanner output into notifications
│   │   ├── WidgetManager.swift           # reloads widget timelines
│   │   ├── SettingsManager.swift
│   │   ├── StatsManager.swift
│   │   ├── MissedManager.swift           # missed queries and the popup's seen list
│   │   └── RefreshManager.swift          # after every write: reload widgets and rebuild notifications
│   ├── Storage/
│   │   ├── SchemaV1.swift                # SwiftData records, one per table
│   │   ├── MigrationPlan.swift
│   │   ├── StoreFactory.swift
│   │   ├── SwiftDataTaskStore.swift      # implements TaskStore
│   │   └── DeviceState.swift             # App Group UserDefaults: timer, seen list, pending open action
│   ├── Intents/                          # every widget button (§8), plus IntentEnvironment
│   ├── Widgets/                          # WidgetSnapshot, SnapshotLoader, WidgetTimelinePlan (shared so TempoTests can test them)
│   ├── DeepLink/
│   │   └── DeepLink.swift
│   └── Utilities/
│       ├── Clock/                        # Clock protocol, SystemClock, FixedClock
│       ├── Extensions/
│       ├── Formatters/                   # minutes, durations, "ends in", day titles
│       └── Logging/                      # os.Logger categories
├── Tempo/                                # app target
│   ├── Info.plist                        # keys that build settings can't express (§2); excluded from resources
│   ├── Tempo.entitlements                # App Group
│   ├── App/                              # TempoApp, AppDelegate, AppDependencies, NavigationRouter
│   ├── Views/
│   │   ├── Root/
│   │   ├── Today/                        # TodayView, TodayViewModel, Components/
│   │   ├── LogTime/
│   │   ├── Tasks/
│   │   ├── History/
│   │   ├── HabitDetail/
│   │   ├── Missed/
│   │   ├── MissedPopup/
│   │   ├── Stats/
│   │   ├── TaskEditor/
│   │   ├── TimerScreen/
│   │   ├── TaskPicker/
│   │   ├── Settings/
│   │   └── Onboarding/
│   ├── Components/                       # views used by more than one screen
│   │   ├── FloatingAddButton/
│   │   ├── TimerBar/
│   │   ├── ConfirmationToast/
│   │   ├── EmptyState/
│   │   ├── WeekdayPicker/
│   │   └── MinuteIntervalPicker/
│   └── Resources/                        # Assets.xcassets, Localizable.xcstrings
├── TempoWidgets/                         # widget extension target
│   ├── Info.plist                        # NSExtension; excluded from resources
│   ├── TempoWidgets.entitlements         # App Group
│   ├── TempoWidgetsBundle.swift
│   ├── Provider/                         # TodayTimelineProvider, TodayEntry
│   ├── Widgets/
│   │   ├── Timer/
│   │   ├── Day/
│   │   ├── Focus/
│   │   ├── Now/
│   │   └── LockScreen/
│   ├── Components/                       # CheckboxToggleStyle, TaskMark, WidgetRow, …
│   └── Resources/                        # the extension's own Assets.xcassets and Localizable.xcstrings
├── TempoTests/                           # app tests: managers with an in-memory store, deep links
└── TempoUITests/                         # UI tests: launch, navigation, links (the app runs with -ui-testing)
```

**Folder rules**
1. Each screen has its own folder in `Views/`, named after the screen without "View". For example, `Today/` holds `TodayView.swift` and `TodayViewModel.swift`.
2. A subview used by only one screen goes in that screen's `Components/` subfolder. When a second screen needs it, it moves to the top-level `Components/`, into its own folder.
3. Business logic lives in `Shared/Managers/` (one manager per area) or in `Core`. Views and view models never touch storage, notifications or widgets directly.
4. Helpers that know nothing about the app go in `Utilities/`.
5. Each widget has its own folder in `TempoWidgets/Widgets/`.
6. Each file holds one type, and the file name matches the type name.
7. A folder with no files yet holds an empty `.gitkeep`, so git keeps it. The project setting `EXCLUDED_SOURCE_FILE_NAMES = .gitkeep` stops the synchronized folders from copying these into the app and extension bundles. A `.gitkeep` can be deleted once its folder has real files.

App Intents and SwiftData records live in `Shared/`, a folder compiled into both targets, rather than in a package. With an iOS 17 deployment target, that's the most reliable setup for App Intents metadata.

---

## 4. Architecture

```
App screens (SwiftUI) ─┐
Widgets (WidgetKit) ───┼──▶ Managers (Shared/Managers) ──▶ Core (pure rules) 
App Intents ───────────┘            │
                                    ▼
                   Storage (SwiftData in the App Group, behind TaskStore)
                   DeviceState (App Group UserDefaults)
```

**Pattern: lightweight MVVM with `@Observable`**
- **Views** display state and forward taps. Nothing else.
- **View models** are `@Observable @MainActor`. Each one holds a single screen's state and calls managers.
- **Managers** hold the side effects and call `Core` for the rules. App screens, widgets and intents all use the same managers.
- **`Core`** is pure and synchronous. Every function takes `now: Date` and a `Calendar` as parameters, never `Date()` or `Calendar.current`.

**Protocols, so previews and tests can use fakes:** `TaskStore`, `Clock`, `NotificationScheduling`, `WidgetReloading`.

```swift
protocol Clock: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }   // the app: Calendar.autoupdatingCurrent; tests: fixed (D-054)
}

protocol TaskStore: Sendable {
    func loadAll() throws -> TaskData                       // every live row of the four task tables
    func write(_ writes: [StoreWrite]) throws               // several rows in one save: all or nothing
    func tasks() throws -> [TaskValue]
    func schedules(taskID: UUID?) throws -> [ScheduleValue]
    @discardableResult func save(_ task: TaskValue) throws -> TaskValue   // upsert by id, sets updatedAt
    func softDeleteTask(id: UUID) throws
    // completions, time entries and settings follow the same shape
}

@Observable @MainActor
final class TodayViewModel {
    private(set) var sections: [DaySection] = []
    private let tasks: TaskManager
    private let clock: Clock

    init(tasks: TaskManager, clock: Clock) { self.tasks = tasks; self.clock = clock }

    func load(day: DayKey) throws {
        sections = try tasks.daySections(for: day, now: clock.now)   // rules live in Core
    }
}
```

**Data-flow rules**
1. **Storage is the single source of truth.** Views and widgets never keep their own copy of data that matters.
2. **Every write goes through a manager.** After each write, `RefreshManager.afterChange()` reloads every widget and rebuilds notifications. In the app this is debounced by 0.5 s. Intents run it immediately.
3. **Load in `.task`, never in `onAppear`,** which can fire more than once.
4. **"Now" always comes from `Clock`.** Statuses that change over time are recalculated inside `TimelineView(.everyMinute)`.
5. **`@Model` objects never leave `Storage/`.** Everything above it works with `Core` value types.

---

## 5. iOS 17 rules

- **Use freely:** SwiftData, Observation, interactive widgets (`Button(intent:)`, `Toggle(isOn:intent:)`), `containerBackground(for:)`, `ContentUnavailableView`, `sensoryFeedback`, `TimelineView`, `.contentMargins`, `#Preview` for widgets, and Swift Charts.
- **Don't use APIs introduced in iOS 18 or later,** even behind `#available`, unless this file says so. That includes `#Index`, `#Unique`, SwiftData history, Control widgets, `.tabViewStyle(.sidebarAdaptable)` and widget push updates.
- **Before closing each task,** run the tests on the latest iOS simulator installed (currently iOS 27.0). Xcode 27 can't install iOS 17 or 18 simulator runtimes, so there's no iOS 17 run (D-052).
- **The deployment target stays iOS 17.0.** The compiler checks every API against it, so an iOS 18+ API used without `#available` fails the build. That check, together with the rules above, is what keeps the app iOS 17-compatible.

---

## 6. Storage

- **One SwiftData record per table** in SPEC §4: `TaskRecord`, `ScheduleRecord`, `CompletionRecord`, `TimeEntryRecord` and `SettingsRecord`.
  - Plain properties, each with a default value.
  - No relationships; tables link through plain `UUID` fields.
  - Enums are stored as raw `String`s, using the exact values from SPEC §4.
  - Day keys are stored as `Int`.
- **Versioning:** use a `VersionedSchema` (`SchemaV1`) and a `SchemaMigrationPlan` from the start.
- **Location:** the store file lives in the App Group container, opened with `cloudKitDatabase: .none`.
- **One `ModelContainer` per process,** held in a static. **Each read or write uses a fresh `ModelContext`.** No `@Query` anywhere.
  - On iOS 17, SwiftData doesn't reliably show writes made by another process (the widget extension), and fresh contexts avoid that problem.
- **Mapping:** records are converted to `Core` value types in `SwiftDataTaskStore`. Views never receive records.
- **Device-only state** (SPEC §4.6) lives in `UserDefaults(suiteName: "group.com.applab.tempo")` as Codable JSON: the timer, the missed seen list, and the pending open action. The "guide completed" flag is app-only and uses `@AppStorage`.

```swift
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [TaskRecord.self, ScheduleRecord.self, CompletionRecord.self, TimeEntryRecord.self, SettingsRecord.self]
    }

    @Model final class TaskRecord {
        var id: UUID = UUID()
        var title: String = ""
        var type: String = "one_time"          // one_time | progress | duration
        var date: Int? = nil                   // one-time: yyyymmdd
        var startDay: Int? = nil               // habits
        var lengthDays: Int? = nil             // nil = ongoing
        var endedOn: Int? = nil
        var createdAt: Date = Date()
        var updatedAt: Date = Date()
        var deletedAt: Date? = nil
        init() {}
    }
    // ScheduleRecord, CompletionRecord, TimeEntryRecord and SettingsRecord follow SPEC §4 the same way
}

enum StoreFactory {
    static let appGroup = "group.com.applab.tempo"
    static let shared: Result<ModelContainer, Error> = Result { try make(inMemory: false) }

    static func make(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
                .appending(path: "Tempo.store")
            config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
    }
}
```

If the store fails to open, the app shows a clear error screen. A widget never crashes; it shows its fallback (SPEC F-17).

---

## 7. Core package

`Packages/Core/Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17), .macOS(.v14)],     // macOS so `swift test` runs on the Mac
    products: [.library(name: "Core", targets: ["Core"])],
    targets: [
        .target(name: "Core"),
        .testTarget(name: "CoreTests", dependencies: ["Core"])
    ]
)
```

Main API. All of it is pure, `Sendable`, and takes `now` and `calendar` as parameters:

| Type | Purpose | SPEC |
|---|---|---|
| `DayKey`, `Weekdays` (OptionSet), `DayPart`, `PartSettings` | Days, weekday bitmask, parts of the day and their validation | §5.1, §5.2 |
| `TaskValue`, `ScheduleValue`, `CompletionValue`, `TimeEntryValue`, `SettingsValue` | Value copies of the tables | §4 |
| `Occurrence`, `Status` | A task on a day, and its status | §5.3, §5.4 |
| `ScheduleEngine` | `occurrences(on:)`, `occurrences(in:)`, `schedule(for:on:)` | §5.3 |
| `StatusRules`, `Editability` | `status(of:now:)`, `canComplete`, `canLogTime`, `canMove` | §5.4, F-04 |
| `DurationMath` | Minutes, weekly goal and weekly total | §5.5 |
| `NextTaskRule` | `next(now:)` and `then(now:)` | §5.6 |
| `MissedQueries`, `MissedFilter` | Missed today, missed earlier, unseen | §5.8 |
| `StatsCalculator` → `StatsSnapshot` | Everything the Stats screen and Habit detail show | §5.7 |
| `ReminderPlanner` → `[PlannedNotification]` | The notification plan | §5.9 |
| `TimelinePlanner` → `[Date]` | Widget update moments | §5.10 |
| `TimerState`, `TimerRules` | The timer state machine: start, pause, resume, finish, discard, alert times | F-06 |

---

## 8. App Intents (widget buttons)

Every intent lives in `Shared/Intents/`, is compiled into both targets, sets `static let isDiscoverable = false`, builds its managers with `IntentEnvironment.make()`, and ends with `await refresh.refreshNowAndWait()`, so widgets reload and notifications are rebuilt before the extension's process ends. Each intent's logic is in a `run(in:)` method that tests call with an in-memory environment.

| Intent | Used by | Opens app | What it does |
|---|---|---|---|
| `ToggleCompletionIntent(taskID, day)` | Now widget checkboxes | No | A `SetValueIntent`: completes or undoes, following F-04 |
| `StartHabitTimerIntent(taskID)` | Now widget ▶ | No | Starts a habit timer |
| `StartGenericTimerIntent` | Timer widget Start | No | Starts a generic timer |
| `PauseTimerIntent`, `ResumeTimerIntent` | Timer widget, Now widget | No | |
| `FinishHabitTimerIntent` | Now widget Done | No | Freezes the clock and saves the time entry |
| `FinishGenericTimerIntent` | Timer widget Done | **Yes** | Freezes the clock and writes the pending open action `chooseTaskForTimer` |
| `DiscardTimerIntent` | Now widget Discard | No | |

`openAppWhenRun` is a static property, so it can't change at runtime. That's why there are two finish intents.

```swift
struct FinishGenericTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Finish Timer"
    static let isDiscoverable = false
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let finished = TimerManager.shared.finish(at: .now)          // freezes the time at the tap
        DeviceState.pendingOpenAction = .chooseTaskForTimer(finished) // the app shows the task picker
        await RefreshManager.afterChange()
        return .result()
    }
}
```

---

## 9. Widgets

```swift
@main
struct TempoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()        // .systemSmall
        DayWidget()          // .systemMedium
        FocusWidget()        // .systemMedium
        NowWidget()          // .systemLarge
        LockScreenWidget()   // .accessoryRectangular, .accessoryInline
    }
}
```

**Configuration and timelines**
- **Configuration:** every widget uses `StaticConfiguration`. There's nothing to configure.
- **Timeline provider:** one `TodayTimelineProvider` for all widgets.
  1. Load a `WidgetSnapshot` with today's and tomorrow's occurrences, the settings and the timer.
  2. Ask `TimelinePlanner` for the update moments.
  3. Create one entry per moment. Each entry recalculates statuses for its own date.
  4. Use the policy `.after(nextMidnight)`.
- **Load failure:** a single fallback entry ("Open Tempo to refresh") with the policy `.after(now + 15 min)`.

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    // WidgetTimelinePlan (Shared/Widgets) loads the snapshot and picks the moments, or falls back to a single
    // failed entry with a retry in 15 minutes.
    let plan = WidgetTimelinePlan.make(now: Date()) { try SnapshotLoader.load() }
    completion(Timeline(entries: plan.moments.map { TodayEntry(date: $0, snapshot: plan.snapshot) },
                        policy: .after(plan.refreshAfter)))
}
```

**Interactive pieces**
- **Checkboxes:** `Toggle(isOn:intent:)` with a custom `CheckboxToggleStyle`. This gives an immediate optimistic check.
- **Other buttons:** `Button(intent:)`.

**Text and progress that update themselves**
- **A clock counting up:** `Text(effectiveStart, style: .timer)`, where `effectiveStart = segmentStart − accumulated`.
- **"in 45 min":** `Text(date, style: .relative)`.
- **Timer progress toward the target:** `ProgressView(timerInterval:countsDown: false)`.

**Taps that open the app**
- The medium and large widgets can use `Link`, for example per column in the Day widget, per row, and for "+N more".
- The small and Lock Screen widgets use only `widgetURL`.

**Appearance**
- Every family calls `containerBackground(for: .widget)`.
- Accented and tinted styles: apply `widgetAccentable()` to the important parts.
- When `showsWidgetContainerBackground` is false, drop the tinted fills.
- A status always comes with an SF Symbol or text.

**Privacy:** when `hide_lock_screen_titles` is on, apply `.privacySensitive()` to titles in the Lock Screen widget.

**Previews:** every widget has a `#Preview(as:)` for each state in its SPEC section.

---

## 10. Notifications

- **Framework and identifiers:** `UNUserNotificationCenter`, with identifiers exactly as in SPEC §5.9.
- **Trigger:** `UNCalendarNotificationTrigger(dateMatching:repeats: false)`, with components that carry no time zone, so reminders float with local time just like the tasks:

  ```swift
  let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
  let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
  ```

- **The limit:** iOS keeps at most **64 pending** notifications per app. `ReminderPlanner` plans 72 hours ahead, and `ReminderManager` keeps the earliest 60.
- **Rebuild:** remove every pending request the app manages, then add the new plan. Rebuilds run one at a time; if another is requested during one, run one more afterward.
- **When to rebuild:**
  - at app launch and when the app becomes active;
  - after every change (`RefreshManager`);
  - when settings change;
  - on a time zone change (`.NSSystemTimeZoneDidChange`) and a day change (`.NSCalendarDayChanged`);
  - during background refresh: `.backgroundTask(.appRefresh("com.applab.tempo.refresh"))`, which also submits the next `BGAppRefreshTaskRequest` with an earliest start one hour away.
- **The timer alert's category:** `TIMER_ALERT`, with `STOP` (`.foreground`; pauses the timer and opens the timer screen) and `KEEP_GOING`.
- **Delegate** (in `AppDelegate`, through `UIApplicationDelegateAdaptor`):
  - `willPresent` returns `[.banner, .list, .sound]`.
  - `didReceive` routes to the destination stored in `userInfo["url"]`. Responses that arrive before the app's dependencies exist are held and delivered once `onResponse` is set.
- **Words:** `Core`'s `ReminderPlanner` returns what each notification is about (`ReminderContent`); `NotificationText` in `Shared/` turns it into localized words, so `Core` stays free of UI text.
- **Permission:** `requestAuthorization(options: [.alert, .sound])`, from guide page 7.
- **From widgets:** intents can rebuild notifications themselves, because `UNUserNotificationCenter` works in the widget extension.

---

## 11. Deep links and launch routing

| URL | Opens |
|---|---|
| `tempo://today[?day=yyyymmdd][&part=noon][&task=<uuid>]` | Today, optionally at a day, part or task |
| `tempo://new[?day=yyyymmdd][&type=one_time\|progress\|duration]` | The editor, with presets |
| `tempo://missed` | The Missed tab |
| `tempo://timer` | The timer screen |

- `DeepLink` (in `Shared/DeepLink/`) parses and builds these URLs, and has unit tests.
- Unknown or malformed URLs open Today.
- The pending open action from `FinishGenericTimerIntent` is read when the app becomes active, and opens the task picker.

**Missed popup timing (SPEC F-08).** iOS can deliver `onOpenURL` slightly after `scenePhase` becomes `.active`. So wait briefly before deciding:

```swift
.onChange(of: scenePhase) { _, phase in
    guard phase == .active else { return }
    Task {
        try? await Task.sleep(for: .milliseconds(500))      // let a widget link or pending action arrive
        guard !router.openedFromLinkThisActivation else { return }
        let unseen = missedManager.unseenToday(now: clock.now)
        if !unseen.isEmpty { router.missedPopup = MissedPopup(tasks: unseen) }
    }
}
```

`openedFromLinkThisActivation` is set by `onOpenURL` and by the pending-open-action handler, and it's reset when the app goes to the background.

---

## 12. UI implementation notes

- **Tabs:** a plain `TabView` with four tabs. The Missed tab uses `.badge(count)`.
- **Timer bar:** placed in each tab's root with `.safeAreaInset(edge: .bottom) { TimerBar() }`, so it sits just above the tab bar.
- **Floating + button:**

  ```swift
  .overlay(alignment: .bottomTrailing) {
      Button { router.openEditor(preset) } label: {
          Image(systemName: "plus").font(.title2.weight(.semibold))
              .frame(width: 56, height: 56)
              .background(.tint, in: Circle())
              .foregroundStyle(.white)
      }
      .padding(20)
      .accessibilityLabel("Add task")
  }
  .contentMargins(.bottom, 88, for: .scrollContent)   // the last row is never hidden under the button
  ```

- **Empty states:** `ContentUnavailableView` with an `actions:` button wherever SPEC F-24 lists one.
- **Missed popup:** a `.sheet` with `.presentationDetents([.medium])`, not a system alert, because a system alert can't lay out a list cleanly.
- **Onboarding:**
  - Presented with `.fullScreenCover` while `@AppStorage("guideCompleted")` is false.
  - Its pages are a `TabView` with `.tabViewStyle(.page)` and `.indexViewStyle(.page(backgroundDisplayMode: .always))`.
- **Time pickers:** SwiftUI's `DatePicker` has no minute interval, so `MinuteIntervalPicker` wraps `UIDatePicker` (`.time` mode, `minuteInterval` 5, or 15 in Settings).
- **Live statuses:** the Today screen and the timer screen sit inside `TimelineView(.everyMinute)`.
- **Charts:** Swift Charts `BarMark` for the Week and Year ranges. The Month calendar is a custom grid.
- **Readable width:**

  ```swift
  extension View {
      func readableWidth() -> some View { frame(maxWidth: 700).frame(maxWidth: .infinity) }
  }
  ```

- **Haptics:** `.sensoryFeedback(.success, trigger:)` on completing a task, and `.selection` on changing day.

---

## 13. Testing

- **`Core`:** Swift Testing (`import Testing`, `@Test`), run with `swift test --package-path Packages/Core`.
  - Always use a fixed `Calendar`: Gregorian, time zone `Europe/London`, locale `en_GB`.
  - Always use a fixed "now". Tuesday 6 Oct 2026 is the reference day.
  - Daylight-saving tests use 29 Mar 2026 (a gap) and 25 Oct 2026 (an overlap) in `Europe/London`.
- **App:** `TempoTests` covers the managers with `StoreFactory.make(inMemory: true)`, plus `DeepLink`.
- **UI:** `TempoUITests` (XCTest) checks what unit tests can't reach: tabs, navigation and links in the running app. The app is launched with `-ui-testing`, which gives it an in-memory store and its own device-only state, optionally `-ui-testing-now <ISO 8601>` to fix its clock, and `-ui-testing-timezone <identifier>` to fix the time zone rules run in (`LaunchOptions`; `UITestApp` always passes Europe/London), and `-ui-testing-sample` to start with `SampleData`, a realistic week of tasks that previews use too. `-ui-testing-no-popup` marks today's missed tasks as seen so the missed popup stays away; `UITestApp` passes it unless a test asks for the popup. `-ui-testing-finished-timer <seconds>` leaves a finished generic timer waiting for the task picker, as the Timer widget's Done does. Keep these few; they're slow. `ScreenshotTests` saves screenshots for review only when `TEST_RUNNER_TEMPO_SCREENSHOTS=<folder>` is passed to `xcodebuild`; otherwise it's skipped. Its widget tests add a widget to the Home Screen through SpringBoard (`XCUIApplication(bundleIdentifier: "com.apple.springboard")`: long press, Edit, Add Widget, search "Tempo") and press its buttons, which is the only way to see a real widget from the command line. They use the simulator's real store, and clean up what they add.
- **Command:** `xcodebuild -scheme Tempo -destination 'platform=iOS Simulator,name=<an available iPhone>' test`. List the devices with `xcrun simctl list devices available`.
- **`Core` on a simulator:** the `Tempo` scheme runs only `TempoTests`, because Xcode ignores a local package's test target in an app scheme. To run the `Core` tests on an iOS simulator (part of the required run on the latest installed iOS, §5), use the package's own scheme from its folder: `cd Packages/Core && xcodebuild -scheme Core -destination 'platform=iOS Simulator,name=<iPhone>,OS=<version>' test`.

**Manual QA checklist (T-32)**
- [ ] With the app closed, the widgets switch at every part boundary, at fixed times and at midnight.
- [ ] Checking off a task in the Now widget updates the app, the other widgets and the pending notifications.
- [ ] A habit timer started from the Now widget shows in the Timer widget and the app. Done in the widget saves without opening the app.
- [ ] A generic timer's Done opens the task picker, with the time frozen.
- [ ] A timer running past midnight saves to the day it started.
- [ ] Every notification kind arrives with the right text, and taps open the right place.
- [ ] The missed popup appears once per task, and not when the app is opened from a widget.
- [ ] Changing the time zone keeps tasks at their wall-clock times.
- [ ] iPad: rotation, Split View and Stage Manager.
- [ ] A full pass on the latest iOS simulator installed (§5, D-052).

---

## 14. Code style

- **Formatting:** `swift-format`, using the `.swift-format` file in the repo. Run it before every commit.
- **Naming:** types `UpperCamelCase`, everything else `lowerCamelCase`. Screens are named `<Name>View` and `<Name>ViewModel`; managers `<Area>Manager`.
- **Safety:**
  - No force unwraps and no `try!` outside tests (the one exception is `StoreFactory`'s App Group URL).
  - Errors are specific `Error` types.
- **Logging:** `os.Logger`, with one category per manager.
- **Text:** all user-facing text goes in `Localizable.xcstrings`, in English only for v1.
- **Accessibility:** every interactive element has an accessibility label, and every status is also given as text.
- **Previews:** every view has a `#Preview` using fake managers and sample data.
- **Commits:** small, one per task or change, with clear messages ("T-12: Today screen sections and rows").

---

## 15. Task notes

These follow the same IDs as SPEC §8. They cover only what's specific to iOS; behavior and acceptance criteria are in SPEC.

- **T-01:**
  - Create the Xcode project "Tempo" (iOS App, SwiftUI).
  - Add a Widget Extension "TempoWidgets", with no Live Activity and no configuration intent.
  - Create `Packages/Core` (§7) and link it to both targets.
  - Create the folder tree (§3), and add `Shared/` to both targets.
  - Add the App Group to both targets and Background fetch to the app (§2). Add the URL scheme, the String Catalog and `.swift-format`.
- **T-02:** `Core/Calendar`.
- **T-03:**
  - `Shared/Storage/*`, including `SchemaV1`, `StoreFactory`, `SwiftDataTaskStore` and `DeviceState`.
  - `SettingsManager` creates the settings row on first launch.
  - Test cross-process reads by writing in the app and reading in a widget preview or provider.
- **T-04:** `Core/Schedule`. `TaskManager.updateHabitSchedule` writes schedule rows as in SPEC §4.2.
- **T-05:** `Core/Status`. `TaskManager` enforces `Editability` before every write.
- **T-06:** `Core/Duration`.
- **T-07:** `Core/NextTask` and `Core/Missed`.
- **T-08:** `Core/Stats`.
- **T-09:** `TempoApp`, `Views/Root`, `NavigationRouter`, `DeepLink`, `Components/FloatingAddButton`, and the timer bar's slot. Settings and History are pushed onto their tab's stack; the editor, timer screen and task picker are sheets. `XCUIApplication.open(_:)` in `TempoUITests` opens links without the system's "Open in Tempo?" prompt that `simctl openurl` shows.
- **T-10:** `Views/Settings` and `Components/MinuteIntervalPicker` (15-minute steps).
- **T-11:**
  - `Views/TaskEditor`, using `Components/WeekdayPicker` and `MinuteIntervalPicker` (5-minute steps).
  - Confirmations use `confirmationDialog`.
- **T-12:**
  - `Views/Today`: `DayStrip`, `PartSection`, `TaskRow` and `DurationRow` in its `Components/`.
  - `Views/LogTime`.
  - `TimelineView(.everyMinute)` for live statuses.
- **T-13:** `Views/Tasks`. The segment is stored with `@AppStorage`.
- **T-14:** `Views/History`, with `.searchable`.
- **T-15:** `Views/HabitDetail`. The month grid stays in its `Components/`.
- **T-16:** `Views/Missed`, with the filter sheet in its `Components/` and the tab badge.
- **T-17:** `Views/MissedPopup`. The popup timing follows §11, and `MissedManager` keeps the seen list.
- **T-18:** `Views/Stats` with Swift Charts.
- **T-19:**
  - `Core/Timer` holds the pure rules.
  - `TimerManager` stores `TimerState` in `DeviceState`.
  - The alert time is handed to `ReminderManager`.
- **T-20:** `Components/TimerBar`, `Views/TimerScreen`, `Views/TaskPicker` and `Components/ConfirmationToast`, plus ▶ in `DurationRow` and Habit detail.
- **T-21:**
  - `ReminderManager` and `Core/Reminders`.
  - `AppDelegate` as the notification delegate, and the `TIMER_ALERT` category.
  - The background refresh task (§10).
- **T-22:**
  - `TempoWidgets/Provider`, `ToggleCompletionIntent` and `RefreshManager` in the intents.
  - Verify cross-process freshness (§6).
- **T-23:** `Widgets/Timer`, plus the start, pause, resume and finish intents.
- **T-24:** `Widgets/Now`, with list mode and timer mode in separate view files, plus `StartHabitTimerIntent`, `FinishHabitTimerIntent` and `DiscardTimerIntent`.
- **T-25:** `Widgets/Day`, with a `Link` per column to `tempo://today?part=…`.
- **T-26:** `Widgets/Focus`, using `NextTaskRule`.
- **T-27:** `Widgets/LockScreen` (`.accessoryRectangular` and `.accessoryInline`), with `.privacySensitive()`.
- **T-28:** `Views/Onboarding` (§12). Page 7 requests notification permission.
- **T-29:** Go through SPEC F-24 one row at a time.
- **T-30:** Use `readableWidth()` on every screen. Test in Stage Manager, Split View and every orientation.
- **T-31:**
  - Use Dynamic Type sizes up to AX5 in the app, and confirm widgets don't clip at the largest non-accessibility size.
  - Test with VoiceOver, and run the Accessibility Inspector audit.
- **T-32:** Run the manual QA checklist in §13.
