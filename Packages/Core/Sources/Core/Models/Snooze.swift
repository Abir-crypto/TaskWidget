import Foundation

/// A snoozed reminder (SPEC F-07, §4.6). Kept on the device only, and cleared when the day changes.
public struct Snooze: Hashable, Codable, Sendable {
    /// The id of the reminder that was snoozed, for example `fixed.<task_id>.<day>` or `ending-soon.<day>.<part>`.
    public var originalID: String
    public var kind: SnoozeKind
    /// When the snoozed reminder fires.
    public var fireDate: Date
    /// The day the original reminder belongs to.
    public var day: DayKey

    public init(originalID: String, kind: SnoozeKind, fireDate: Date, day: DayKey) {
        self.originalID = originalID
        self.kind = kind
        self.fireDate = fireDate
        self.day = day
    }
}

/// Which kind of reminder was snoozed. Only fixed-time and ending-soon reminders can be (SPEC F-07).
public enum SnoozeKind: String, Codable, Hashable, Sendable {
    case fixed
    case endingSoon = "ending_soon"
}

/// The day's snoozes. A list for another day counts as empty, so snoozes clear when the day changes (SPEC §4.6).
public struct SnoozeList: Hashable, Codable, Sendable {
    public var day: DayKey
    public var snoozes: [Snooze]

    public init(day: DayKey, snoozes: [Snooze] = []) {
        self.day = day
        self.snoozes = snoozes
    }

    /// The snoozes that still apply on `today`.
    public func snoozes(on today: DayKey) -> [Snooze] {
        day == today ? snoozes : []
    }
}
