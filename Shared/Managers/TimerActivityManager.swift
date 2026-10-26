import ActivityKit
import Core
import Foundation

/// Keeps the timer's Live Activity in step with the one timer (SPEC F-31): it starts when a timer exists, updates
/// on every change, and ends when the timer is finished or discarded. Only the app can do this, so the timer intents
/// are Live Activity intents, which run in the app's process (ios.md §8).
@MainActor
final class TimerActivityManager {
    private let store: any TaskStore
    private let deviceState: DeviceState
    private let clock: any Clock

    init(store: any TaskStore, deviceState: DeviceState, clock: any Clock) {
        self.store = store
        self.deviceState = deviceState
        self.clock = clock
    }

    /// Whether this process is the app. The widget extension can't start Live Activities.
    static var isApp: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    /// Brings the Live Activity in line with the stored timer. If the user turned Live Activities off, or the device
    /// doesn't show them (iPad), nothing happens. If the system ended the activity, the next change starts a new one.
    func sync() async {
        guard Self.isApp, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let activities = Activity<TimerActivityAttributes>.activities
        guard let timer = deviceState.timer else {
            for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
            return
        }
        let attributes = TimerActivityAttributes(kind: timer.kind, habitID: timer.habitID, startDay: timer.startDay)
        let content: ActivityContent<TimerActivityAttributes.ContentState>
        do {
            let snapshot = Snapshot(
                data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: clock.calendar)
            content = ActivityContent(
                state: Self.contentState(for: timer, snapshot: snapshot),
                staleDate: nil)
        } catch {
            Log.liveActivity.error("Couldn't read the timer's habit for the Live Activity: \(error)")
            return
        }
        var current: Activity<TimerActivityAttributes>?
        for activity in activities {
            if current == nil, activity.attributes == attributes, activity.activityState == .active {
                current = activity
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        if let current {
            await current.update(content)
        } else {
            do {
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                Log.liveActivity.error("Couldn't start the timer's Live Activity: \(error)")
            }
        }
    }

    /// What the Live Activity shows for a timer: the clock, and for a habit timer its name, the time logged earlier
    /// on the timer's day and its target that day (SPEC F-31).
    static func contentState(
        for timer: TimerState, snapshot: Snapshot
    ) -> TimerActivityAttributes.ContentState {
        let clock = TimerClockValue(state: timer)
        var runningSince: Date?
        var pausedSeconds = 0
        switch clock {
        case .running(let since): runningSince = since
        case .paused(let seconds): pausedSeconds = seconds
        }
        let habitID = timer.habitID
        let earlier =
            habitID.map { id in
                snapshot.activity.timeEntries.filter { $0.taskID == id && $0.day == timer.startDay }
                    .reduce(0) { $0 + $1.seconds }
            } ?? 0
        return TimerActivityAttributes.ContentState(
            runningSince: runningSince, pausedSeconds: pausedSeconds,
            habitTitle: habitID.flatMap { snapshot.engine.task(id: $0)?.title },
            earlierSeconds: earlier,
            targetMinutes: habitID.flatMap { snapshot.engine.schedule(for: $0, on: timer.startDay)?.targetMinutes },
            hidesName: snapshot.settings.hideLockScreenTitles,
            tint: snapshot.settings.tintColor.storedValue)
    }
}
