import Foundation

/// The source of "now" and of the calendar for everything above `Core` (ios.md §4).
///
/// Nothing outside this folder calls `Date()` or `Calendar.current` for rules; it asks a `Clock`.
protocol Clock: Sendable {
    var now: Date { get }
    /// The calendar rules run in: the user's current calendar, time zone and region.
    var calendar: Calendar { get }
}
