import Foundation

/// The one timer on the device (SPEC §4.6, F-06). Kept on the device only and never synced.
public struct TimerState: Hashable, Codable, Sendable {
    public var kind: TimerKind
    /// The habit being timed. `nil` for a generic timer.
    public var habitID: UUID?
    /// The day the timer was started; its time is saved to this day.
    public var startDay: DayKey
    /// Seconds counted in earlier, finished segments.
    public var accumulatedSeconds: TimeInterval
    /// When the current segment started, or `nil` while paused.
    public var segmentStart: Date?

    public init(
        kind: TimerKind,
        habitID: UUID?,
        startDay: DayKey,
        accumulatedSeconds: TimeInterval = 0,
        segmentStart: Date?
    ) {
        self.kind = kind
        self.habitID = habitID
        self.startDay = startDay
        self.accumulatedSeconds = accumulatedSeconds
        self.segmentStart = segmentStart
    }
}
