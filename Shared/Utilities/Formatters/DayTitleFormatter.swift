import Core
import Foundation

/// A day's title: "Today", "Tomorrow", "Yesterday", or a short date like "Thu 8 Oct" (SPEC F-10).
enum DayTitleFormatter {
    static func title(for day: DayKey, today: DayKey, calendar: Calendar) -> String {
        switch today.days(to: day, in: calendar) {
        case 0: String(localized: "Today")
        case 1: String(localized: "Tomorrow")
        case -1: String(localized: "Yesterday")
        default: shortDate(day, calendar: calendar)
        }
    }

    /// "Thu 8 Oct", in the user's language and date order.
    static func shortDate(_ day: DayKey, calendar: Calendar) -> String {
        let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.abbreviated).day().month(.abbreviated)
        return day.startDate(in: calendar).formatted(style)
    }
}
