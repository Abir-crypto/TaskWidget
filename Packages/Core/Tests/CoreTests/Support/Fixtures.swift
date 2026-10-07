import Foundation

@testable import Core

/// Builds tasks and their schedules for `Core` tests. Creation times increase with each task, so creation
/// order is the order the fixtures are made in.
struct Fixtures {
    private(set) var data = TaskData()
    private var created = TestCalendar.date(2026, 9, 1, 8)

    var calendar: Calendar { TestCalendar.london }

    var engine: ScheduleEngine { ScheduleEngine(data: data, calendar: calendar) }

    func snapshot(settings: SettingsValue = .defaults) -> Snapshot {
        Snapshot(data: data, settings: settings, calendar: calendar)
    }

    /// The status of a task's occurrence on a day, at a moment.
    func status(_ task: TaskValue, on day: DayKey = TestCalendar.today, at now: Date) -> Status? {
        let snapshot = snapshot()
        return snapshot.engine.occurrence(of: task, on: day).map { snapshot.status(of: $0, now: now) }
    }

    func occurrence(_ task: TaskValue, on day: DayKey = TestCalendar.today) -> Occurrence? {
        engine.occurrence(of: task, on: day)
    }

    private mutating func nextCreatedAt() -> Date {
        created = created.addingTimeInterval(60)
        return created
    }

    @discardableResult
    mutating func oneTime(
        _ title: String = "Task", on date: DayKey = TestCalendar.today, timing: Timing = .anytime
    ) -> TaskValue {
        let createdAt = nextCreatedAt()
        let task = TaskValue(title: title, type: .oneTime, date: date, createdAt: createdAt)
        data.tasks.append(task)
        data.schedules.append(
            ScheduleValue(
                taskID: task.id, effectiveFrom: .distantPast, timing: timing, weekdays: .none, createdAt: createdAt))
        return task
    }

    @discardableResult
    mutating func habit(
        _ title: String = "Habit",
        type: TaskType = .progress,
        timing: Timing = .anytime,
        weekdays: Weekdays = .all,
        start: DayKey = TestCalendar.oct(1),
        length: Int? = nil,
        endedOn: DayKey? = nil,
        target: Int? = nil
    ) -> TaskValue {
        let createdAt = nextCreatedAt()
        let task = TaskValue(
            title: title, type: type, startDay: start, lengthDays: length, endedOn: endedOn, createdAt: createdAt)
        data.tasks.append(task)
        data.schedules.append(
            ScheduleValue(
                taskID: task.id, effectiveFrom: start, timing: timing, weekdays: weekdays,
                targetMinutes: type == .duration ? (target ?? 30) : nil, createdAt: createdAt))
        return task
    }

    @discardableResult
    mutating func duration(
        _ title: String = "Read",
        timing: Timing = .anytime,
        weekdays: Weekdays = .all,
        start: DayKey = TestCalendar.oct(1),
        target: Int = 30
    ) -> TaskValue {
        habit(title, type: .duration, timing: timing, weekdays: weekdays, start: start, target: target)
    }

    /// Adds a schedule row for a habit from `day` onward, copying the latest row's other fields.
    mutating func reschedule(
        _ task: TaskValue, from day: DayKey, timing: Timing? = nil, weekdays: Weekdays? = nil, target: Int? = nil
    ) {
        guard
            let latest = data.schedules.filter({ $0.taskID == task.id }).max(by: { $0.effectiveFrom < $1.effectiveFrom }
            )
        else { return }
        data.schedules.append(
            ScheduleValue(
                taskID: task.id, effectiveFrom: day, timing: timing ?? latest.timing,
                weekdays: weekdays ?? latest.weekdays, targetMinutes: target ?? latest.targetMinutes,
                createdAt: nextCreatedAt()))
    }

    mutating func complete(_ task: TaskValue, on day: DayKey) {
        data.completions.append(CompletionValue(taskID: task.id, day: day, createdAt: nextCreatedAt()))
    }

    mutating func log(_ task: TaskValue, minutes: Int, on day: DayKey, seconds extra: Int = 0) {
        data.timeEntries.append(
            TimeEntryValue(
                taskID: task.id, day: day, seconds: minutes * 60 + extra, source: .manual, createdAt: nextCreatedAt()))
    }

    mutating func delete(_ task: TaskValue) {
        guard let index = data.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        data.tasks[index].deletedAt = TestCalendar.date(2026, 10, 6, 9)
    }
}
