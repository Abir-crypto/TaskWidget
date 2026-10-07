import Foundation

/// Finds which tasks occur on which days, and which schedule applies (SPEC §5.3, §4.2).
public struct ScheduleEngine: Sendable {
    public let calendar: Calendar
    /// Live tasks in creation order.
    public let tasks: [TaskValue]
    private let tasksByID: [UUID: TaskValue]
    /// Each task's live schedules, oldest `effectiveFrom` first.
    private let schedulesByTask: [UUID: [ScheduleValue]]

    public init(tasks: [TaskValue], schedules: [ScheduleValue], calendar: Calendar) {
        self.calendar = calendar
        let live = tasks.filter { $0.deletedAt == nil }
        self.tasks = live.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
        self.tasksByID = Dictionary(live.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.schedulesByTask = Dictionary(grouping: schedules.filter { $0.deletedAt == nil }, by: \.taskID)
            .mapValues { $0.sorted { $0.effectiveFrom < $1.effectiveFrom } }
    }

    public init(data: TaskData, calendar: Calendar) {
        self.init(tasks: data.tasks, schedules: data.schedules, calendar: calendar)
    }

    public func task(id: UUID) -> TaskValue? {
        tasksByID[id]
    }

    /// A task's schedules, oldest first.
    public func schedules(for taskID: UUID) -> [ScheduleValue] {
        schedulesByTask[taskID] ?? []
    }

    /// The schedule for day `d`: the row with the greatest `effectiveFrom` that is ≤ `d` (SPEC §4.2).
    public func schedule(for taskID: UUID, on day: DayKey) -> ScheduleValue? {
        schedules(for: taskID).last { $0.effectiveFrom <= day }
    }

    /// The most recent schedule, which applies from today onward.
    public func latestSchedule(for taskID: UUID) -> ScheduleValue? {
        schedules(for: taskID).last
    }

    /// Whether `day` is within the task's life: its date for a one-time task, or between a habit's start and
    /// last day. Time can be logged on any of a habit's live days, scheduled or not (SPEC F-05).
    public func isLive(_ task: TaskValue, on day: DayKey) -> Bool {
        guard task.deletedAt == nil else { return false }
        guard task.type.isHabit else { return task.date == day }
        guard let start = task.startDay, start <= day else { return false }
        if let last = task.lastDay(in: calendar), day > last { return false }
        return true
    }

    /// The occurrence of a task on a day, or `nil` when it doesn't occur (SPEC §5.3).
    public func occurrence(of task: TaskValue, on day: DayKey) -> Occurrence? {
        guard isLive(task, on: day), let schedule = schedule(for: task.id, on: day) else { return nil }
        if task.type.isHabit, !schedule.weekdays.contains(day.weekday(in: calendar)) { return nil }
        return Occurrence(task: task, day: day, schedule: schedule)
    }

    public func occurrence(taskID: UUID, on day: DayKey) -> Occurrence? {
        task(id: taskID).flatMap { occurrence(of: $0, on: day) }
    }

    /// Every occurrence on a day, in task creation order.
    public func occurrences(on day: DayKey) -> [Occurrence] {
        tasks.compactMap { occurrence(of: $0, on: day) }
    }

    /// Every occurrence from `first` through `last`, day by day.
    public func occurrences(from first: DayKey, through last: DayKey) -> [Occurrence] {
        first.through(last, in: calendar).flatMap { occurrences(on: $0) }
    }

    /// A habit's occurrences from `first` through `last`.
    public func occurrences(of task: TaskValue, from first: DayKey, through last: DayKey) -> [Occurrence] {
        first.through(last, in: calendar).compactMap { occurrence(of: task, on: $0) }
    }
}
