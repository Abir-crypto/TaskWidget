import Foundation

/// A real moment read as floating local time: the day key and the minute of day (SPEC §5.1).
public struct LocalTime: Hashable, Sendable {
    public let day: DayKey
    /// Minutes after local midnight, 0–1439.
    public let minute: Int

    public init(day: DayKey, minute: Int) {
        self.day = day
        self.minute = minute
    }

    /// Reads `date` on the wall clock of `calendar`'s time zone.
    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        self.day = DayKey(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
        self.minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// The real moment this local time names (SPEC §5.1 handles daylight-saving gaps and overlaps).
    public func date(in calendar: Calendar) -> Date {
        day.date(atMinute: minute, in: calendar)
    }
}
