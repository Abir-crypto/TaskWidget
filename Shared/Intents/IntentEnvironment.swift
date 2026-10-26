import Foundation

/// The managers an App Intent needs, built inside whichever process runs it (usually the widget extension).
/// Every intent ends with `refresh.refreshNowAndWait()`, which reloads every widget and rebuilds the
/// notifications before the process can end (ios.md §8).
@MainActor
struct IntentEnvironment {
    let tasks: TaskManager
    let timer: TimerManager
    let refresh: RefreshManager
    let deviceState: DeviceState

    /// The real managers: the App Group store, the system clock, WidgetKit and the notification center.
    /// The timer's Live Activity is kept in step too; only the app's process can do that, which is why the timer
    /// intents are Live Activity intents (SPEC F-31).
    static func make() throws -> IntentEnvironment {
        let clock = SystemClock()
        let store = SwiftDataTaskStore(container: try StoreFactory.shared.get(), clock: clock)
        let environment = make(
            store: store, deviceState: .shared, clock: clock, widgets: WidgetManager(),
            scheduler: SystemNotificationScheduler())
        environment.refresh.timerActivity = TimerActivityManager(store: store, deviceState: .shared, clock: clock)
        return environment
    }

    static func make(
        store: any TaskStore, deviceState: DeviceState, clock: any Clock, widgets: any WidgetReloading,
        scheduler: any NotificationScheduling
    ) -> IntentEnvironment {
        let refresh = RefreshManager(widgets: widgets)
        refresh.reminders = ReminderManager(store: store, deviceState: deviceState, scheduler: scheduler, clock: clock)
        let tasks = TaskManager(store: store, clock: clock, refresh: refresh, deviceState: deviceState)
        let timer = TimerManager(deviceState: deviceState, tasks: tasks, clock: clock, refresh: refresh)
        return IntentEnvironment(tasks: tasks, timer: timer, refresh: refresh, deviceState: deviceState)
    }
}
