import Core
import Foundation

/// A timer clock a widget can draw without knowing "now": counting up from a fixed moment while running, or a
/// frozen number of seconds while paused (ios.md §9).
enum TimerClockValue: Hashable {
    /// Counting up from this moment: the segment's start moved back by the earlier segments.
    case running(since: Date)
    /// Paused at this many seconds.
    case paused(seconds: Int)

    init(state: TimerState) {
        if let segmentStart = state.segmentStart {
            self = .running(since: segmentStart.addingTimeInterval(-state.accumulatedSeconds))
        } else {
            self = .paused(seconds: Int(state.accumulatedSeconds))
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    /// "05:12" or "1:05:12", for a paused clock.
    static func text(seconds: Int) -> String {
        let pattern: Duration.TimeFormatStyle.Pattern = seconds >= 3_600 ? .hourMinuteSecond : .minuteSecond
        return Duration.seconds(seconds).formatted(.time(pattern: pattern))
    }
}
