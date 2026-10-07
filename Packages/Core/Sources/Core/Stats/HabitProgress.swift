import Foundation

/// The short progress lines shown for a habit in the Tasks tab (SPEC F-11).
public enum HabitProgress {
    /// Progress habits: scheduled days of this week that are done, out of the week's scheduled days
    /// ("4 of 5 this week"). Counts days between the start and last day only.
    public static func week(of task: TaskValue, snapshot: Snapshot, today: DayKey) -> (done: Int, scheduled: Int) {
        let math = DurationMath(snapshot: snapshot)
        let week = math.week(containing: today)
        let days = math.scheduledDays(of: task, from: week.first, through: week.last)
        let done = days.filter { snapshot.activity.isCompleted(taskID: task.id, day: $0) }.count
        return (done, days.count)
    }

    /// Habits with a set length: which day of it today is ("Day 12 of 30"). `nil` without a length, or before
    /// the start. Never past the length.
    public static func dayOfLength(of task: TaskValue, today: DayKey, calendar: Calendar) -> (day: Int, length: Int)? {
        guard let start = task.startDay, let length = task.lengthDays, start <= today else { return nil }
        return (min(start.days(to: today, in: calendar) + 1, length), length)
    }

    /// Whether a habit hasn't started yet.
    public static func hasNotStarted(_ task: TaskValue, today: DayKey) -> Bool {
        guard let start = task.startDay else { return false }
        return start > today
    }
}
