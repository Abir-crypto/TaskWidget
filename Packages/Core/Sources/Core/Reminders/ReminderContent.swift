import Foundation

/// What a planned notification is about (SPEC F-07, §5.9). The app turns it into words.
public enum ReminderContent: Hashable, Sendable {
    /// When a part starts: its tasks that aren't done, and for Morning also the open Anytime tasks.
    case partStart(day: DayKey, part: DayPart, items: [ReminderItem], anytime: [ReminderItem])
    /// Before a part ends: what's still not done.
    case endingSoon(day: DayKey, part: DayPart, minutesLeft: Int, items: [ReminderItem])
    /// Before a fixed-time task.
    case fixed(day: DayKey, item: ReminderItem, leadMinutes: Int)
    /// The end-of-day recap: what will be missed and what will still be open at the recap time.
    case recap(day: DayKey, missed: [ReminderItem], open: [ReminderItem])
    /// A timer has been running for a whole number of alert periods.
    case timerAlert(habitTitle: String?, runningMinutes: Int)

    /// Where tapping the notification leads (SPEC F-07).
    public var destination: ReminderDestination {
        switch self {
        case .partStart(let day, let part, _, _), .endingSoon(let day, let part, _, _):
            .today(day: day, part: part, taskID: nil)
        case .fixed(let day, let item, _):
            .today(day: day, part: nil, taskID: item.taskID)
        case .recap:
            .missed
        case .timerAlert:
            .timer
        }
    }
}
