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

    /// The notifications the current data calls for, as of now. Snoozes that have fired, or whose reminder no
    /// longer applies, are cleared on the way (SPEC F-07, §4.6).
    func notifications() throws -> [ScheduledNotification] {
        let snapshot = Snapshot(
            data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: clock.calendar)
        let timer = deviceState.timer.map { state in
            ReminderPlanner.RunningTimer(
                state: state, habitTitle: state.habitID.flatMap { snapshot.engine.task(id: $0)?.title })
        }
        let snoozes = liveSnoozes(in: snapshot)
        return ReminderPlanner.plan(snapshot: snapshot, now: clock.now, timer: timer, snoozes: snoozes).map { planned in
            ScheduledNotification(
                id: planned.id, fireDate: planned.fireDate,
                title: NotificationText.title(for: planned.content, missedStyle: snapshot.settings.missedStyle),
                body: NotificationText.body(for: planned.content),
                url: NotificationText.url(for: planned.content.destination),
                categoryIdentifier: planned.id == "timer-alert"
                    ? NotificationCategory.timerAlert
                    : planned.snooze.flatMap { NotificationCategory.snoozeCategory(for: $0.options) },
                snooze: planned.snooze)
        }
    }

    /// Today's snoozes that still apply, writing back the list without the rest. A list from another day reads
    /// as empty, so snoozes clear when the day changes.
    private func liveSnoozes(in snapshot: Snapshot) -> [Snooze] {
        let today = DayKey(clock.now, calendar: clock.calendar)
        let stored = deviceState.snoozes?.snoozes(on: today) ?? []
        let live = ReminderPlanner.liveSnoozes(stored, snapshot: snapshot, now: clock.now)
        if live != stored || (deviceState.snoozes != nil && stored.isEmpty) {
            deviceState.snoozes = live.isEmpty ? nil : SnoozeList(day: today, snoozes: live)
        }
        return live
    }

    /// Snooze tapped on a notification: the reminder comes back after the chosen time, but never later than 5 minutes
    /// before its part ends, and replaces any earlier snooze of the same reminder (SPEC F-07, D-110, D-122). Then the
    /// plan is rebuilt. Nothing opens.
    func snooze(_ request: SnoozeRequest) async {
        let today = DayKey(clock.now, calendar: clock.calendar)
        var snoozes = (deviceState.snoozes?.snoozes(on: today) ?? []).filter { $0.originalID != request.originalID }
        if let fire = SnoozeRules.fireDate(tappedAt: clock.now, option: request.option, partEnd: request.partEnd) {
            snoozes.append(Snooze(originalID: request.originalID, kind: request.kind, fireDate: fire, day: request.day))
        } else {
            Log.reminders.info("Snooze landed too close to the part's end; nothing scheduled")
        }
        deviceState.snoozes = snoozes.isEmpty ? nil : SnoozeList(day: today, snoozes: snoozes)
        await rebuild()
    }
}
