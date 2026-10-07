import Core
import Foundation

/// The timer as the timer bar and timer screen show it (SPEC F-06).
struct ActiveTimer: Hashable {
    let state: TimerState
    /// The habit's title, or "Timer" for a generic timer.
    let title: String
    /// Duration habits: minutes logged earlier today, before this timer.
    let minutesBefore: Int
    /// Duration habits: today's target.
    let targetMinutes: Int?

    var isRunning: Bool { TimerRules.isRunning(state) }
    var isHabit: Bool { state.kind == .habit }
}
