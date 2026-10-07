import Foundation

/// A week, month or year shown by the Stats screen (SPEC F-14).
public struct StatsRange: Hashable, Sendable {
    public let kind: StatsRangeKind
    public let first: DayKey
    public let last: DayKey

    public init(kind: StatsRangeKind, first: DayKey, last: DayKey) {
        self.kind = kind
        self.first = first
        self.last = last
    }

    /// The range of `kind` that contains `day`. Weeks start on the region's first weekday.
    public static func containing(_ day: DayKey, kind: StatsRangeKind, calendar: Calendar) -> StatsRange {
        switch kind {
        case .week:
            let first = day.startOfWeek(in: calendar)
            return StatsRange(kind: .week, first: first, last: first.adding(days: 6, in: calendar))
        case .month:
            let first = day.startOfMonth
            let last = first.adding(days: 31, in: calendar).startOfMonth.adding(days: -1, in: calendar)
            return StatsRange(kind: .month, first: first, last: last)
        case .year:
            return StatsRange(
                kind: .year, first: day.startOfYear, last: DayKey(year: day.year, month: 12, day: 31))
        }
    }

    /// The range just before this one.
    public func previous(in calendar: Calendar) -> StatsRange {
        StatsRange.containing(first.adding(days: -1, in: calendar), kind: kind, calendar: calendar)
    }

    /// The range just after this one.
    public func next(in calendar: Calendar) -> StatsRange {
        StatsRange.containing(last.adding(days: 1, in: calendar), kind: kind, calendar: calendar)
    }

    public func contains(_ day: DayKey) -> Bool {
        first <= day && day <= last
    }

    /// Every day of the range.
    public func days(in calendar: Calendar) -> [DayKey] {
        first.through(last, in: calendar)
    }

    /// Whether the Stats screen can move back to the previous range: not before the first task was created.
    public func canGoBack(firstDay: DayKey?, calendar: Calendar) -> Bool {
        guard let firstDay else { return false }
        return previous(in: calendar).last >= firstDay
    }

    /// Whether it can move forward: never past the current period.
    public func canGoForward(today: DayKey, calendar: Calendar) -> Bool {
        next(in: calendar).first <= today
    }
}

/// The Stats screen's range choices.
public enum StatsRangeKind: String, CaseIterable, Hashable, Sendable {
    case week
    case month
    case year
}
