import Foundation

/// Which days can still change at a moment (SPEC §5.11): today fully, and yesterday for corrections until today's
/// Afternoon starts (`noon_start`). Read once, from the clock and the part times, wherever F-04 is checked.
public struct EditWindow: Hashable, Sendable {
    public let today: DayKey
    /// Yesterday while it can still be corrected; `nil` once the window has closed.
    public let correctableDay: DayKey?
    /// When the window closes today, as a minute of day (Afternoon's start); `nil` once it has closed.
    public let closingMinute: Int?

    public init(today: DayKey, correctableDay: DayKey? = nil, closingMinute: Int? = nil) {
        self.today = today
        self.correctableDay = correctableDay
        self.closingMinute = correctableDay == nil ? nil : closingMinute
    }

    /// `editable(d, now)` from §5.11. The window ends at today's `noon_start`, read now, so changing the start time
    /// moves the end of the window at once.
    public init(now: LocalTime, parts: PartSettings, calendar: Calendar) {
        let closing = parts.start(of: .noon)
        let isOpen = now.minute < closing
        self.init(
            today: now.day, correctableDay: isOpen ? now.day.adding(days: -1, in: calendar) : nil,
            closingMinute: isOpen ? closing : nil)
    }

    /// The same moment, read from a date.
    public init(now: Date, parts: PartSettings, calendar: Calendar) {
        self.init(now: LocalTime(now, calendar: calendar), parts: parts, calendar: calendar)
    }

    public func access(to day: DayKey) -> DayAccess {
        if day > today { return .future }
        if day == today { return .today }
        if day == correctableDay { return .correction }
        return .none
    }
}

/// How much a day can change (SPEC F-04, §5.11).
public enum DayAccess: Hashable, Sendable {
    /// A day after today: F-04's Future days row.
    case future
    /// Today: F-04's Today row, until midnight.
    case today
    /// Yesterday before today's Afternoon starts: complete, undo, log time and delete time entries, nothing else.
    case correction
    /// Earlier days, and yesterday after the window: read-only, except for the timer (F-06).
    case none

    /// Completing, undoing, logging time and deleting time entries are allowed on today and in the window.
    public var allowsCorrections: Bool { self == .today || self == .correction }
}
