import Core
import Foundation

/// Turns `ReminderPlanner`'s plan into pending notifications (SPEC F-07, §5.9, ios.md §10).
///
/// Every rebuild replaces the whole pending set with the plan for the next 72 hours (the earliest 60).
/// Rebuilds run one at a time; one requested during another runs once more afterward.
@MainActor
final class ReminderManager {
    private let store: any TaskStore
    private let deviceState: DeviceState
    private let scheduler: any NotificationScheduling
    private let clock: any Clock
    private var isRebuilding = false
    private var needsAnotherRebuild = false

    init(store: any TaskStore, deviceState: DeviceState, scheduler: any NotificationScheduling, clock: any Clock) {
        self.store = store
        self.deviceState = deviceState
        self.scheduler = scheduler
        self.clock = clock
    }

    /// Rebuilds the pending notifications from the current data. With permission refused, nothing is scheduled.
    func rebuild() async {
        guard !isRebuilding else {
            needsAnotherRebuild = true
            return
        }
        isRebuilding = true
        repeat {
            needsAnotherRebuild = false
            await rebuildOnce()
        } while needsAnotherRebuild
        isRebuilding = false
    }

    private func rebuildOnce() async {
        guard await scheduler.permission() == .allowed else {
            await scheduler.replacePending(with: [], calendar: clock.calendar)
            return
        }
        do {
            await scheduler.replacePending(with: try notifications(), calendar: clock.calendar)
        } catch {
            Log.reminders.error("Couldn't plan notifications: \(error)")
        }
    }

    /// The notifications the current data calls for, as of now.
    func notifications() throws -> [ScheduledNotification] {
        let snapshot = Snapshot(
            data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: clock.calendar)
        let timer = deviceState.timer.map { state in
            ReminderPlanner.RunningTimer(
                state: state, habitTitle: state.habitID.flatMap { snapshot.engine.task(id: $0)?.title })
        }
        return ReminderPlanner.plan(snapshot: snapshot, now: clock.now, timer: timer).map { planned in
            ScheduledNotification(
                id: planned.id, fireDate: planned.fireDate,
                title: NotificationText.title(for: planned.content, missedStyle: snapshot.settings.missedStyle),
                body: NotificationText.body(for: planned.content),
                url: NotificationText.url(for: planned.content.destination),
                categoryIdentifier: planned.id == "timer-alert" ? NotificationCategory.timerAlert : nil)
        }
    }
}
