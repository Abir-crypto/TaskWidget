import Foundation

/// A calendar day written as `yyyymmdd`, for example `20261006` (SPEC §1.3, §5.1).
///
/// Day keys are floating local days: they mean the same wall-calendar day in every time zone.
/// Arithmetic always goes through a `Calendar`, never through the integer.
public struct DayKey: RawRepresentable, Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: Int

    /// Wraps a raw `yyyymmdd` value without checking it. `0` is used for one-time schedules (SPEC §4.2).
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(year: Int, month: Int, day: Int) {
        self.rawValue = year * 10_000 + month * 100 + day
    }

    /// The local day that contains `date`.
    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    /// The value used for a one-time task's single schedule row (SPEC §4.2).
    public static let distantPast = DayKey(rawValue: 0)

    public var year: Int { rawValue / 10_000 }
    public var month: Int { rawValue / 100 % 100 }
    public var day: Int { rawValue % 100 }

    /// Whether the key names a real calendar day.
    public func isValid(in calendar: Calendar) -> Bool {
        guard rawValue > 0, let date = noon(in: calendar) else { return false }
        return DayKey(date, calendar: calendar) == self
    }

    /// The first moment of the day in `calendar`'s time zone.
    public func startDate(in calendar: Calendar) -> Date {
        guard let noon = noon(in: calendar) else { return Date(timeIntervalSinceReferenceDate: 0) }
        return calendar.startOfDay(for: noon)
    }

    /// The real moment for a minute of this day (SPEC §5.1).
    ///
    /// A time inside a daylight-saving gap becomes the next valid moment. A repeated time uses its first
    /// occurrence. Minute 1440 is midnight, the start of the next day.
    public func date(atMinute minute: Int, in calendar: Calendar) -> Date {
        if minute >= DayKey.minutesPerDay {
            return adding(days: 1, in: calendar).date(atMinute: minute - DayKey.minutesPerDay, in: calendar)
        }
        let start = startDate(in: calendar)
        let clamped = max(0, minute)
        if clamped == 0 { return start }
        let wanted = DateComponents(hour: clamped / 60, minute: clamped % 60)
        return calendar.nextDate(
            after: start,
            matching: wanted,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? start.addingTimeInterval(TimeInterval(clamped * 60))
    }

    /// This day moved by `days` calendar days (negative moves back).
    public func adding(days: Int, in calendar: Calendar) -> DayKey {
        guard let noon = noon(in: calendar), let moved = calendar.date(byAdding: .day, value: days, to: noon)
        else { return self }
        return DayKey(moved, calendar: calendar)
    }

    /// The number of calendar days from this day to `other` (positive when `other` is later).
    public func days(to other: DayKey, in calendar: Calendar) -> Int {
        guard let from = noon(in: calendar), let to = other.noon(in: calendar) else { return 0 }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to))
            .day ?? 0
    }

    public func weekday(in calendar: Calendar) -> Weekday {
        guard let noon = noon(in: calendar) else { return .monday }
        return Weekday(calendarWeekday: calendar.component(.weekday, from: noon)) ?? .monday
    }

    /// The first day of the week that contains this day, using the calendar's first weekday (SPEC §5.1).
    public func startOfWeek(in calendar: Calendar) -> DayKey {
        let offset = (weekday(in: calendar).calendarWeekday - calendar.firstWeekday + 7) % 7
        return adding(days: -offset, in: calendar)
    }

    /// The seven days of the week that contains this day, in calendar order.
    public func week(in calendar: Calendar) -> [DayKey] {
        let first = startOfWeek(in: calendar)
        return (0..<7).map { first.adding(days: $0, in: calendar) }
    }

    /// The first day of this day's month.
    public var startOfMonth: DayKey { DayKey(year: year, month: month, day: 1) }

    /// The first day of this day's year.
    public var startOfYear: DayKey { DayKey(year: year, month: 1, day: 1) }

    /// Every day from `self` through `last`, inclusive. Empty when `last` is earlier.
    public func through(_ last: DayKey, in calendar: Calendar) -> [DayKey] {
        guard self <= last else { return [] }
        var days: [DayKey] = []
        var day = self
        while day <= last {
            days.append(day)
            day = day.adding(days: 1, in: calendar)
        }
        return days
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.rawValue < rhs.rawValue }

    public var description: String { String(rawValue) }

    public static let minutesPerDay = 1440

    /// Noon is used as the anchor for day arithmetic because it always exists, even on daylight-saving days.
    private func noon(in calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    public init(from decoder: any Decoder) throws {
        self.rawValue = try decoder.singleValueContainer().decode(Int.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
