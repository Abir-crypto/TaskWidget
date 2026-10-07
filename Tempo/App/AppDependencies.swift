import Core
import Foundation
import Observation

/// The app's managers, created once at launch and shared by every screen through the environment.
@Observable
@MainActor
final class AppDependencies {
    let clock: any Clock
    let store: any TaskStore
    let deviceState: DeviceState
    let notifications: any NotificationScheduling
    let refresh: RefreshManager
    let settings: SettingsManager
    let tasks: TaskManager
    let missed: MissedManager
    let stats: StatsManager
    let timer: TimerManager
    let reminders: ReminderManager

    init(
        clock: any Clock,
        store: any TaskStore,
        deviceState: DeviceState,
        notifications: any NotificationScheduling,
        widgets: any WidgetReloading
    ) {
        self.clock = clock
        self.store = store
        self.deviceState = deviceState
        self.notifications = notifications
        self.refresh = RefreshManager(widgets: widgets)
        self.settings = SettingsManager(store: store, refresh: refresh)
        self.tasks = TaskManager(store: store, clock: clock, refresh: refresh, deviceState: deviceState)
        self.missed = MissedManager(tasks: tasks, deviceState: deviceState, clock: clock)
        self.stats = StatsManager(tasks: tasks, clock: clock)
        self.timer = TimerManager(deviceState: deviceState, tasks: tasks, clock: clock, refresh: refresh)
        self.reminders = ReminderManager(store: store, deviceState: deviceState, scheduler: notifications, clock: clock)
        refresh.reminders = reminders
    }

    /// The real dependencies: the shared App Group store, the system clock and WidgetKit. UI tests get an
    /// in-memory store and their own device-only state instead (`LaunchOptions`).
    static func live(options: LaunchOptions = LaunchOptions()) throws -> AppDependencies {
        if options.isUITesting {
            let calendar = options.calendar
            let clock: any Clock = options.fixedNow.map { FixedClock($0, calendar: calendar) } ?? SystemClock()
            let deviceState = DeviceState(defaults: UserDefaults(suiteName: "ui-testing") ?? .standard)
            deviceState.reset()
            let store = SwiftDataTaskStore(container: try StoreFactory.make(inMemory: true), clock: clock)
            if options.usesSampleData { SampleData.populate(store: store, clock: clock) }
            let dependencies = AppDependencies(
                clock: clock,
                store: store,
                deviceState: deviceState,
                notifications: FixedNotificationScheduler(permission: .allowed),
                widgets: WidgetManager())
            if options.suppressesMissedPopup, let unseen = try? dependencies.missed.unseenToday() {
                dependencies.missed.markSeen(unseen.map(\.id))
            }
            if let seconds = options.finishedTimerSeconds {
                let day = DayKey(clock.now, calendar: clock.calendar)
                deviceState.pendingOpenAction = .chooseTaskForTimer(
                    FinishedTimer(habitID: nil, day: day, seconds: seconds))
            }
            return dependencies
        }
        let clock = SystemClock()
        let container = try StoreFactory.shared.get()
        return AppDependencies(
            clock: clock,
            store: SwiftDataTaskStore(container: container, clock: clock),
            deviceState: .shared,
            notifications: SystemNotificationScheduler(),
            widgets: WidgetManager()
        )
    }

    /// In-memory dependencies for previews, at Tuesday 6 Oct 2026, 10:30 in the current time zone, optionally
    /// filled with `SampleData`.
    static func preview(hour: Int = 10, minute: Int = 30, sample: Bool = false) -> AppDependencies {
        let calendar = Calendar.autoupdatingCurrent
        let now = DayKey(year: 2026, month: 10, day: 6).date(atMinute: hour * 60 + minute, in: calendar)
        let clock = FixedClock(now, calendar: calendar)
        let store: any TaskStore
        do {
            store = SwiftDataTaskStore(container: try StoreFactory.make(inMemory: true), clock: clock)
        } catch {
            preconditionFailure("In-memory store failed: \(error)")
        }
        let dependencies = AppDependencies(
            clock: clock, store: store,
            deviceState: DeviceState(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            notifications: FixedNotificationScheduler(permission: .allowed),
            widgets: WidgetManager())
        dependencies.prepare()
        if sample { SampleData.populate(store: store, clock: clock) }
        return dependencies
    }

    /// Runs once at launch: makes sure the settings row exists (SPEC §4.5).
    func prepare() {
        do {
            try settings.loadOrCreate()
        } catch {
            Log.settings.error("Couldn't create the settings row: \(error)")
        }
    }
}
