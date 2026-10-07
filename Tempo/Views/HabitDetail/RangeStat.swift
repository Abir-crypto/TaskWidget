import Core
import Foundation

/// One line of Habit detail's stats: this week, this month or this year (SPEC F-13).
struct RangeStat: Identifiable, Hashable {
    let kind: StatsRangeKind
    let rate: CompletionRate
    /// Duration habits: minutes logged in the range.
    let minutes: Int?
    /// Duration habits, this week only: the weekly goal.
    let weeklyGoal: Int?

    var id: StatsRangeKind { kind }
}
