import ActivityKit
import Core
import Foundation

/// The timer's Live Activity (SPEC F-31): which timer it is, and what changes as it runs. Shared by the app, which
/// starts, updates and ends it, and the widget extension, which draws it.
struct TimerActivityAttributes: ActivityAttributes, Hashable {
    /// A generic timer or a habit timer.
    let kind: TimerKind
    /// The habit for a habit timer.
    let habitID: UUID?
    /// The day the timer started, which its time counts for (SPEC F-06).
    let startDay: DayKey

    struct ContentState: Codable, Hashable {
        /// The clock: counting up from a moment while running, or frozen while paused.
        var runningSince: Date?
        var pausedSeconds: Int
        /// The habit's name, or `nil` for a generic timer ("Timer").
        var habitTitle: String?
        /// Time already logged to the habit on the timer's day, before this timer.
        var earlierSeconds: Int
        /// The habit's target that day, in minutes.
        var targetMinutes: Int?
        /// Hide task names on the Lock Screen (SPEC F-16, F-31).
        var hidesName: Bool
        /// The theme color's stored value (SPEC F-27).
        var tint: String

        var clock: TimerClockValue {
            if let runningSince { return .running(since: runningSince) }
            return .paused(seconds: pausedSeconds)
        }
    }
}
