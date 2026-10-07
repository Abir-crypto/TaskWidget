import Core
import Foundation

extension Weekday {
    /// The weekday's full name in the user's language ("Monday").
    func name(in calendar: Calendar) -> String {
        calendar.standaloneWeekdaySymbols[calendarWeekday - 1]
    }

    /// The short name ("Mon").
    func shortName(in calendar: Calendar) -> String {
        calendar.shortStandaloneWeekdaySymbols[calendarWeekday - 1]
    }

    /// The narrowest name ("M").
    func initial(in calendar: Calendar) -> String {
        calendar.veryShortStandaloneWeekdaySymbols[calendarWeekday - 1]
    }
}
