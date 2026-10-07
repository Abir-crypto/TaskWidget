import Foundation

/// Formats a minute of the day as a time, following the user's 12- or 24-hour setting ("06:00", "6:00 AM").
enum TimeOfDayFormatter {
    static func string(minute: Int, locale: Locale = .autoupdatingCurrent) -> String {
        // Minutes are floating local time, so they're formatted on a fixed UTC day with no daylight saving.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let style = Date.FormatStyle(
            date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: .gmt)
        return date(minute: minute).formatted(style)
    }

    /// The moment `minute` minutes after midnight on 1 Jan 2001 UTC, used to show and pick times of day.
    static func date(minute: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: TimeInterval(minute * 60))
    }

    /// The minute of day of a moment made by `date(minute:)`.
    static func minute(of date: Date) -> Int {
        Int((date.timeIntervalSinceReferenceDate / 60).rounded()) % 1440
    }
}
