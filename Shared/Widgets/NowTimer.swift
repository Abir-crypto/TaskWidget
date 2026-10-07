import Core
import Foundation

/// Timer mode (SPEC F-21): the habit, the clock, progress toward today's target, and the controls.
struct NowTimer: Hashable {
    let habitID: UUID
    let title: String
    let clock: TimerClockValue
    /// Seconds logged to the habit on the timer's day before this timer.
    let loggedSeconds: Int
    let targetMinutes: Int?
    /// The timer's seconds at the entry's moment.
    let elapsedSeconds: Int

    /// Minutes today including the timer ("22 of 30 min today").
    var minutesToday: Int { (loggedSeconds + elapsedSeconds) / 60 }

    /// The progress bar's span: from when the day's time would have started to when the target is reached.
    var progressInterval: ClosedRange<Date>? {
        guard let targetMinutes, case .running(let since) = clock else { return nil }
        let start = since.addingTimeInterval(TimeInterval(-loggedSeconds))
        return start...start.addingTimeInterval(TimeInterval(max(targetMinutes * 60, 1)))
    }
}
