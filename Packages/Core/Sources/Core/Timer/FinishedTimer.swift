import Foundation

/// A timer stopped by Done, with its time frozen at the tap (SPEC F-06).
public struct FinishedTimer: Hashable, Codable, Sendable {
    /// The habit it was timing, or `nil` for a generic timer.
    public var habitID: UUID?
    /// The day the timer was started, which the time is saved to.
    public var day: DayKey
    /// Whole seconds counted, excluding paused time.
    public var seconds: Int

    public init(habitID: UUID?, day: DayKey, seconds: Int) {
        self.habitID = habitID
        self.day = day
        self.seconds = seconds
    }
}
