import Foundation

/// What can change, and when (SPEC F-04, §5.11).
///
/// Today allows everything until midnight. Yesterday can still be corrected until today's Afternoon starts:
/// completed, undone, and given or relieved of time. Earlier days are read-only. On future days, one-time tasks can be
/// completed early, moved, edited or deleted, but habits can't be completed and time can't be logged.
public enum Editability {
    /// Whether a one-time task or progress habit can be marked done (or undone) on its day: one-time tasks today,
    /// on future days and in the correction window; progress habits today and in the window.
    public static func canComplete(_ occurrence: Occurrence, in window: EditWindow) -> Bool {
        let access = window.access(to: occurrence.day)
        switch occurrence.type {
        case .oneTime: return access != .none
        case .progress: return access.allowsCorrections
        case .duration: return false
        }
    }

    /// Whether time can be logged to a duration habit on `day`: today, or yesterday in the correction window, and
    /// only between its start and last day (SPEC F-05). A timer started on an earlier day is the other exception,
    /// handled by the timer.
    public static func canLogTime(task: TaskValue, day: DayKey, in window: EditWindow, calendar: Calendar) -> Bool {
        guard task.type == .duration, task.deletedAt == nil, window.access(to: day).allowsCorrections else {
            return false
        }
        guard let start = task.startDay, start <= day else { return false }
        if let last = task.lastDay(in: calendar), day > last { return false }
        return true
    }

    /// Whether a time entry can be deleted: today's, and yesterday's in the correction window (SPEC F-05).
    public static func canDeleteTimeEntry(_ entry: TimeEntryValue, in window: EditWindow) -> Bool {
        window.access(to: entry.day).allowsCorrections
    }

    /// Whether a one-time task can be moved: today or a future day, and not already done (D-060).
    public static func canMove(_ occurrence: Occurrence, status: Status, today: DayKey) -> Bool {
        occurrence.type == .oneTime && occurrence.day >= today && status != .done
    }

    /// What moving does: a task Missed today is copied to tomorrow; otherwise its date moves forward one day.
    public static func movePlan(
        for occurrence: Occurrence, status: Status, today: DayKey, calendar: Calendar
    ) -> MovePlan? {
        guard canMove(occurrence, status: status, today: today) else { return nil }
        let next = occurrence.day.adding(days: 1, in: calendar)
        if occurrence.day == today, status == .missed { return .copy(to: next) }
        return .moveDate(to: next)
    }

    /// Whether a one-time task can be edited or deleted: only while its date is today or later.
    public static func canEditOneTime(_ task: TaskValue, today: DayKey) -> Bool {
        guard task.type == .oneTime, let date = task.date else { return false }
        return date >= today
    }

    /// Whether a habit's schedule, length or start can still be edited: only while it hasn't ended.
    public static func canEditHabitSchedule(_ task: TaskValue, today: DayKey, calendar: Calendar) -> Bool {
        task.type.isHabit && !task.hasEnded(today: today, calendar: calendar)
    }
}
