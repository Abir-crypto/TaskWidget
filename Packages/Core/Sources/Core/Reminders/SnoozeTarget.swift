import Foundation

/// What a fixed-time or ending-soon notification needs for its Snooze buttons (SPEC F-07, §5.9): which reminder it
/// is, when its part ends, and the options that land at least 5 minutes before that.
public struct SnoozeTarget: Hashable, Sendable {
    /// The original reminder's id, `fixed.<task_id>.<day>` or `ending-soon.<day>.<part>`, also for a snoozed one.
    public let originalID: String
    public let kind: SnoozeKind
    public let day: DayKey
    /// When the reminder's part of the day ends.
    public let partEnd: Date
    /// The options offered, judged from the notification's fire time. Empty means no Snooze buttons.
    public let options: [SnoozeOption]

    public init(originalID: String, kind: SnoozeKind, day: DayKey, partEnd: Date, options: [SnoozeOption]) {
        self.originalID = originalID
        self.kind = kind
        self.day = day
        self.partEnd = partEnd
        self.options = options
    }
}
