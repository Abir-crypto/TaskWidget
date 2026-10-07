import Core
import Foundation

/// What a widget timeline should hold (ios.md §9): the snapshot, an entry for each update moment of today and
/// tomorrow, and when to ask again — after midnight, or in 15 minutes if the data couldn't be read (SPEC F-17).
struct WidgetTimelinePlan: Sendable {
    /// `nil` when the data couldn't be read; the widget then shows "Open Tempo to refresh".
    let snapshot: WidgetSnapshot?
    let moments: [Date]
    let refreshAfter: Date

    /// How soon to try again after a load failure.
    static let retryInterval: TimeInterval = 15 * 60

    static func make(now: Date, load: () throws -> WidgetSnapshot) -> WidgetTimelinePlan {
        let snapshot: WidgetSnapshot
        do {
            snapshot = try load()
        } catch {
            Log.storage.error("Widget couldn't load its data: \(error)")
            return WidgetTimelinePlan(
                snapshot: nil, moments: [now], refreshAfter: now.addingTimeInterval(retryInterval))
        }
        return WidgetTimelinePlan(
            snapshot: snapshot,
            moments: TimelinePlanner.moments(from: now, snapshot: snapshot.core, timerGoal: timerGoal(snapshot)),
            refreshAfter: TimelinePlanner.nextMidnight(after: now, calendar: snapshot.calendar))
    }

    /// For a habit timer, widgets also redraw the moment the target is reached (SPEC §5.10).
    private static func timerGoal(_ snapshot: WidgetSnapshot) -> TimelinePlanner.TimerGoal? {
        guard let timer = snapshot.timer, let habitID = timer.habitID,
            let target = snapshot.core.engine.schedule(for: habitID, on: timer.startDay)?.targetMinutes
        else { return nil }
        return TimelinePlanner.TimerGoal(
            state: timer, loggedSeconds: snapshot.core.activity.seconds(taskID: habitID, day: timer.startDay),
            targetMinutes: target)
    }
}
