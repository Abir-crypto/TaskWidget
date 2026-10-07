import Foundation

/// Minutes, goals and totals for duration habits (SPEC §5.5, F-05).
public struct DurationMath: Sendable {
    public let engine: ScheduleEngine
    public let activity: ActivityLog

    public init(engine: ScheduleEngine, activity: ActivityLog) {
        self.engine = engine
        self.activity = activity
    }

    public init(snapshot: Snapshot) {
        self.init(engine: snapshot.engine, activity: snapshot.activity)
    }

    private var calendar: Calendar { engine.calendar }

    /// `minutes(task, d)`: whole minutes, rounded down from the day's summed seconds.
    public func minutes(taskID: UUID, day: DayKey) -> Int {
        activity.minutes(taskID: taskID, day: day)
    }

    /// Days in `first…last` that fall between the habit's start and last day, scheduled or not.
    public func liveDays(of task: TaskValue, from first: DayKey, through last: DayKey) -> [DayKey] {
        first.through(last, in: calendar).filter { engine.isLive(task, on: $0) }
    }

    /// Days in `first…last` between the start and last day whose weekday is in that day's schedule.
    public func scheduledDays(of task: TaskValue, from first: DayKey, through last: DayKey) -> [DayKey] {
        engine.occurrences(of: task, from: first, through: last).map(\.day)
    }

    /// The sum of each scheduled day's own target, so a target changed mid-range adds up day by day.
    public func goal(of task: TaskValue, from first: DayKey, through last: DayKey) -> Int {
        engine.occurrences(of: task, from: first, through: last).reduce(0) { $0 + ($1.schedule.targetMinutes ?? 0) }
    }

    /// The sum of the minutes on every live day of the range, scheduled or not.
    public func total(of task: TaskValue, from first: DayKey, through last: DayKey) -> Int {
        liveDays(of: task, from: first, through: last).reduce(0) { $0 + minutes(taskID: task.id, day: $1) }
    }

    /// The week that contains `day`, starting on the region's first weekday.
    public func week(containing day: DayKey) -> (first: DayKey, last: DayKey) {
        let first = day.startOfWeek(in: calendar)
        return (first, first.adding(days: 6, in: calendar))
    }

    /// `weeklyGoal`, `weeklyTotal` and whether the goal is met, for the week that contains `day`.
    public func weeklyProgress(of task: TaskValue, containing day: DayKey) -> GoalProgress {
        let week = week(containing: day)
        return GoalProgress(
            minutes: total(of: task, from: week.first, through: week.last),
            goal: goal(of: task, from: week.first, through: week.last))
    }
}
