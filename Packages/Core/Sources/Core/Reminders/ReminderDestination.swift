import Foundation

/// Where a notification opens the app (SPEC F-07, F-09).
public enum ReminderDestination: Hashable, Sendable {
    case today(day: DayKey, part: DayPart?, taskID: UUID?)
    case missed
    case timer
}
