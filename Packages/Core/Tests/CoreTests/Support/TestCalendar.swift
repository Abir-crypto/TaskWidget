import Foundation

@testable import Core

/// The fixed calendar every `Core` test uses (ios.md §13): Gregorian, Europe/London, en_GB.
enum TestCalendar {
    static let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        calendar.locale = Locale(identifier: "en_GB")
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Tuesday 6 Oct 2026, the reference "today" (SPEC §8).
    static let today = DayKey(year: 2026, month: 10, day: 6)

    /// A real moment on the London wall clock.
    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        DayKey(year: year, month: month, day: day).date(atMinute: hour * 60 + minute, in: london)
    }

    /// A moment on Tuesday 6 Oct 2026.
    static func today(_ hour: Int, _ minute: Int = 0) -> Date {
        date(2026, 10, 6, hour, minute)
    }

    /// A day in October 2026.
    static func oct(_ day: Int) -> DayKey {
        DayKey(year: 2026, month: 10, day: day)
    }
}
