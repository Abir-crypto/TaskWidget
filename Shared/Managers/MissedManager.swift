import Core
import Foundation

/// Missed queries for the app: today's missed count for the tab badge, the Missed tab's lists, and the
/// popup's seen list (SPEC F-08, §5.8).
@MainActor
final class MissedManager {
    private let tasks: TaskManager
    private let deviceState: DeviceState
    private let clock: any Clock

    init(tasks: TaskManager, deviceState: DeviceState, clock: any Clock) {
        self.tasks = tasks
        self.deviceState = deviceState
        self.clock = clock
    }

    /// Today's Missed and Short occurrences.
    func missedToday() throws -> [MissedItem] {
        MissedQueries.missedToday(in: try tasks.snapshot(), now: clock.now)
    }

    /// The Missed tab's badge: how many tasks are Missed or Short today.
    func missedTodayCount() -> Int {
        do {
            return try missedToday().count
        } catch {
            Log.tasks.error("Couldn't count today's missed tasks: \(error)")
            return 0
        }
    }
}
