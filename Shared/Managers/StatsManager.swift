import Core
import Foundation

/// Stats for the Stats screen (SPEC F-14), computed by `Core`'s `StatsCalculator` from fresh data.
@MainActor
final class StatsManager {
    private let tasks: TaskManager
    private let clock: any Clock

    init(tasks: TaskManager, clock: any Clock) {
        self.tasks = tasks
        self.clock = clock
    }

    /// Every card's data for a range, and the day the first task was created (the limit for going back).
    func stats(for range: StatsRange) throws -> (snapshot: StatsSnapshot, firstDay: DayKey?) {
        let calculator = StatsCalculator(snapshot: try tasks.snapshot(), now: clock.now)
        return (calculator.stats(for: range), calculator.firstDay)
    }
}
