import Core
import Foundation

/// Describes when a task happens: "Mon, Wed, Fri · Evening", "Every day · 12:30", "Anytime" (SPEC F-11).
enum ScheduleFormatter {
    static func timing(_ timing: Timing) -> String {
        switch timing {
        case .fixed(let minute): TimeOfDayFormatter.string(minute: minute)
        case .part(let part): part.title
        case .anytime: String(localized: "Anytime")
        }
    }

    /// "Every day", "Weekdays", "Weekends", or short names in the region's order ("Mon, Wed, Fri").
    static func weekdays(_ weekdays: Weekdays, calendar: Calendar) -> String {
        if weekdays == .all { return String(localized: "Every day") }
        if weekdays == [.monday, .tuesday, .wednesday, .thursday, .friday] { return String(localized: "Weekdays") }
        if weekdays == [.saturday, .sunday] { return String(localized: "Weekends") }
        return Weekday.ordered(firstWeekday: calendar.firstWeekday)
            .filter { weekdays.contains($0) }
            .map { $0.shortName(in: calendar) }
            .formatted(.list(type: .and, width: .narrow))
    }

    /// A habit's weekdays and timing, or a one-time task's timing.
    static func summary(_ schedule: ScheduleValue, type: TaskType, calendar: Calendar) -> String {
        guard type.isHabit else { return timing(schedule.timing) }
        return "\(weekdays(schedule.weekdays, calendar: calendar)) · \(timing(schedule.timing))"
    }
}
