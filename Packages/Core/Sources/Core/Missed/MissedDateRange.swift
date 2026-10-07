/// The date ranges offered by the Missed filter (SPEC F-08).
public enum MissedDateRange: Hashable, Sendable {
    case all
    /// The current week, starting on the region's first weekday.
    case thisWeek
    /// The current calendar month.
    case thisMonth
    /// From `first` through `last`, inclusive.
    case custom(first: DayKey, last: DayKey)
}
