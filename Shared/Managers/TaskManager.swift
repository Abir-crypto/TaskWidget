import Core
import Foundation

/// Creates and edits tasks, their schedules, completions and time entries (ios.md §3).
///
/// Every write goes through here and ends with `RefreshManager.afterChange()`. The rules come from `Core`.
@MainActor
final class TaskManager {
    private let store: any TaskStore
    private let clock: any Clock
    private let refresh: RefreshManager

    init(store: any TaskStore, clock: any Clock, refresh: RefreshManager) {
        self.store = store
        self.clock = clock
        self.refresh = refresh
    }

    var calendar: Calendar { clock.calendar }
    var today: DayKey { DayKey(clock.now, calendar: calendar) }

    /// Every live row, read fresh from storage.
    func data() throws -> TaskData {
        try store.loadAll()
    }

    func engine() throws -> ScheduleEngine {
        ScheduleEngine(data: try store.loadAll(), calendar: calendar)
    }

    /// The part start times in use.
    func parts() throws -> PartSettings {
        try store.settings()?.parts ?? .defaults
    }

    /// Whether a timing has already ended on a day (SPEC F-15, D-035).
    func isOver(_ timing: Timing, on day: DayKey) throws -> Bool {
        TaskRules.isOver(timing, on: day, now: LocalTime(clock.now, calendar: calendar), parts: try parts())
    }

    /// The data, the settings and the rules, read fresh.
    func snapshot() throws -> Snapshot {
        Snapshot(data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: calendar)
    }

    // MARK: Complete

    /// Marks a one-time task or progress habit done on a day (SPEC F-04). Doing it twice changes nothing.
    func complete(taskID: UUID, day: DayKey) throws {
        let snapshot = try snapshot()
        let occurrence = try completableOccurrence(taskID: taskID, day: day, in: snapshot)
        guard !snapshot.activity.isCompleted(taskID: taskID, day: occurrence.day) else { return }
        try store.write([.completion(CompletionValue(taskID: taskID, day: occurrence.day, createdAt: clock.now))])
        refresh.afterChange()
    }

    /// Marks a task not done: every completion row for the (task, day) pair is soft-deleted (SPEC §4.3).
    func undoCompletion(taskID: UUID, day: DayKey) throws {
        let snapshot = try snapshot()
        let occurrence = try completableOccurrence(taskID: taskID, day: day, in: snapshot)
        let now = clock.now
        let writes: [StoreWrite] = try store.completions(taskID: taskID)
            .filter { $0.day == occurrence.day }
            .map { completion in
                var deleted = completion
                deleted.deletedAt = now
                return .completion(deleted)
            }
        guard !writes.isEmpty else { return }
        try store.write(writes)
        refresh.afterChange()
    }

    /// Completes or undoes, whichever is the opposite of the current state.
    func toggleCompletion(taskID: UUID, day: DayKey) throws {
        if try snapshot().activity.isCompleted(taskID: taskID, day: day) {
            try undoCompletion(taskID: taskID, day: day)
        } else {
            try complete(taskID: taskID, day: day)
        }
    }

    private func completableOccurrence(taskID: UUID, day: DayKey, in snapshot: Snapshot) throws -> Occurrence {
        guard let task = snapshot.engine.task(id: taskID) else { throw TaskError.notFound }
        guard task.type != .duration else { throw TaskError.wrongType }
        guard let occurrence = snapshot.engine.occurrence(of: task, on: day),
            Editability.canComplete(occurrence, today: today)
        else { throw TaskError.notAllowed }
        return occurrence
    }

    // MARK: Time

    /// Log time: adds a manual entry to today (SPEC F-05). 5–480 minutes in 5-minute steps, and only on a day
    /// between the habit's start and last day.
    @discardableResult
    func logTime(taskID: UUID, minutes: Int) throws -> TimeEntryValue {
        if let error = TaskRules.logTimeError(minutes) { throw TaskError.invalid(error) }
        let task = try existingTask(taskID)
        guard task.type == .duration else { throw TaskError.wrongType }
        guard Editability.canLogTime(task: task, day: today, today: today, calendar: calendar) else {
            throw TaskError.notAllowed
        }
        let entry = TimeEntryValue(
            taskID: taskID, day: today, seconds: minutes * 60, source: .manual, createdAt: clock.now)
        try store.write([.timeEntry(entry)])
        refresh.afterChange()
        return entry
    }

    /// Deletes one of today's time entries. Entries on past days are read-only (SPEC F-05).
    func deleteTimeEntry(id: UUID) throws {
        guard var entry = try store.timeEntries(taskID: nil).first(where: { $0.id == id }) else {
            throw TaskError.notFound
        }
        guard Editability.canDeleteTimeEntry(entry, today: today) else { throw TaskError.notAllowed }
        entry.deletedAt = clock.now
        try store.write([.timeEntry(entry)])
        refresh.afterChange()
    }

    // MARK: Move

    /// Move to tomorrow, or Move to next day on a future day (SPEC F-04). A task that isn't missed changes its
    /// date. A task Missed today stays on today as missed, and a copy with the same title and timing is created
    /// for tomorrow. Returns the task that is now on the next day.
    @discardableResult
    func moveToNextDay(taskID: UUID) throws -> TaskValue {
        let snapshot = try snapshot()
        guard let task = snapshot.engine.task(id: taskID), let date = task.date else { throw TaskError.notFound }
        guard task.type == .oneTime else { throw TaskError.wrongType }
        guard let occurrence = snapshot.engine.occurrence(of: task, on: date) else { throw TaskError.notFound }
        let status = snapshot.status(of: occurrence, now: clock.now)
        guard let plan = Editability.movePlan(for: occurrence, status: status, today: today, calendar: calendar)
        else { throw TaskError.notAllowed }
        switch plan {
        case .moveDate(let day):
            var moved = task
            moved.date = day
            try store.write([.task(moved)])
            refresh.afterChange()
            return moved
        case .copy(let day):
            let now = clock.now
            let copy = TaskValue(title: task.title, type: .oneTime, date: day, createdAt: now)
            let schedule = ScheduleValue(
                taskID: copy.id, effectiveFrom: .distantPast, timing: occurrence.timing, weekdays: .none,
                createdAt: now)
            try store.write([.task(copy), .schedule(schedule)])
            refresh.afterChange()
            return copy
        }
    }

    // MARK: Create

    /// Adds a one-time task (SPEC F-01, F-15). Its date can't be in the past.
    @discardableResult
    func createOneTime(title: String, date: DayKey, timing: Timing) throws -> TaskValue {
        if let error = TaskRules.titleError(title) ?? TaskRules.timingError(timing) { throw TaskError.invalid(error) }
        guard date >= today else { throw TaskError.invalid(.dayInPast) }
        guard try !isOver(timing, on: date) else { throw TaskError.invalid(.partAlreadyOver) }
        let now = clock.now
        let task = TaskValue(title: TaskRules.normalizedTitle(title), type: .oneTime, date: date, createdAt: now)
        let schedule = ScheduleValue(
            taskID: task.id, effectiveFrom: .distantPast, timing: timing, weekdays: .none, createdAt: now)
        try store.write([.task(task), .schedule(schedule)])
        refresh.afterChange()
        return task
    }

    /// Adds a progress or duration habit (SPEC F-01, F-03, F-15). It can't start before today.
    @discardableResult
    func createHabit(
        type: TaskType,
        title: String,
        timing: Timing,
        weekdays: Weekdays,
        startDay: DayKey,
        lengthDays: Int?,
        targetMinutes: Int?,
        allowingEndedPart: Bool = false
    ) throws -> TaskValue {
        guard type.isHabit else { throw TaskError.wrongType }
        let error =
            TaskRules.titleError(title)
            ?? TaskRules.scheduleError(type: type, timing: timing, weekdays: weekdays, targetMinutes: targetMinutes)
            ?? TaskRules.lengthError(lengthDays)
        if let error { throw TaskError.invalid(error) }
        guard startDay >= today else { throw TaskError.invalid(.dayInPast) }
        if !allowingEndedPart, try isOver(timing, on: startDay) { throw TaskError.invalid(.partAlreadyOver) }
        let now = clock.now
        let task = TaskValue(
            title: TaskRules.normalizedTitle(title), type: type, startDay: startDay, lengthDays: lengthDays,
            createdAt: now)
        let schedule = ScheduleValue(
            taskID: task.id, effectiveFrom: startDay, timing: timing, weekdays: weekdays,
            targetMinutes: targetMinutes, createdAt: now)
        try store.write([.task(task), .schedule(schedule)])
        refresh.afterChange()
        return task
    }

    // MARK: Edit

    /// Renames a task. The new title applies everywhere, including history (SPEC F-03).
    func rename(taskID: UUID, to title: String) throws {
        if let error = TaskRules.titleError(title) { throw TaskError.invalid(error) }
        var task = try existingTask(taskID)
        if task.type == .oneTime, !Editability.canEditOneTime(task, today: today) { throw TaskError.notAllowed }
        let normalized = TaskRules.normalizedTitle(title)
        guard task.title != normalized else { return }
        task.title = normalized
        try store.write([.task(task)])
        refresh.afterChange()
    }

    /// Changes a task's timing, weekdays or target, keeping the schedule history (SPEC §4.2, F-03).
    /// For a habit the change applies from today; days before today keep their schedule.
    func updateSchedule(taskID: UUID, timing: Timing, weekdays: Weekdays, targetMinutes: Int?) throws {
        let task = try existingTask(taskID)
        try requireEditableSchedule(task)
        let weekdays = task.type.isHabit ? weekdays : .none
        if let error = TaskRules.scheduleError(
            type: task.type, timing: timing, weekdays: weekdays, targetMinutes: targetMinutes)
        {
            throw TaskError.invalid(error)
        }
        let write = ScheduleHistory.edit(
            task: task, schedules: try store.schedules(taskID: taskID), timing: timing, weekdays: weekdays,
            targetMinutes: targetMinutes, today: today, now: clock.now)
        guard let write else { return }
        // A change that applies today can't move the task into a part that has already ended (D-035, D-069).
        let appliesToday = task.type.isHabit ? (task.startDay ?? today) <= today : task.date == today
        if appliesToday, try isOver(timing, on: today) { throw TaskError.invalid(.partAlreadyOver) }
        try store.write([.schedule(write.schedule)])
        refresh.afterChange()
    }

    /// Edits a one-time task's title, date and timing in one write (SPEC F-15). Only while its date is today or
    /// later; the new date can't be in the past, and a changed date or timing can't be in a part that has ended.
    func updateOneTime(taskID: UUID, title: String, date: DayKey, timing: Timing) throws {
        if let error = TaskRules.titleError(title) ?? TaskRules.timingError(timing) { throw TaskError.invalid(error) }
        var task = try existingTask(taskID)
        guard task.type == .oneTime else { throw TaskError.wrongType }
        guard Editability.canEditOneTime(task, today: today) else { throw TaskError.notAllowed }
        guard date >= today else { throw TaskError.invalid(.dayInPast) }
        guard var schedule = try store.schedules(taskID: taskID).first else { throw TaskError.notFound }
        let moved = task.date != date || schedule.timing != timing
        if moved, try isOver(timing, on: date) { throw TaskError.invalid(.partAlreadyOver) }
        var writes: [StoreWrite] = []
        let normalized = TaskRules.normalizedTitle(title)
        if task.title != normalized || task.date != date {
            task.title = normalized
            task.date = date
            writes.append(.task(task))
        }
        if schedule.timing != timing {
            schedule.timing = timing
            writes.append(.schedule(schedule))
        }
        guard !writes.isEmpty else { return }
        try store.write(writes)
        refresh.afterChange()
    }

    /// Changes a habit's set length, which moves its last day (SPEC F-03). If the new last day would be before
    /// today, the habit ends as with End habit and keeps its days so far (D-058).
    func setLength(taskID: UUID, lengthDays: Int?) throws {
        if let error = TaskRules.lengthError(lengthDays) { throw TaskError.invalid(error) }
        var task = try existingTask(taskID)
        guard task.type.isHabit, let start = task.startDay else { throw TaskError.wrongType }
        try requireEditableSchedule(task)
        if let lengthDays, start.adding(days: lengthDays - 1, in: calendar) < today {
            try endHabit(taskID: taskID)
            return
        }
        guard task.lengthDays != lengthDays else { return }
        task.lengthDays = lengthDays
        try store.write([.task(task)])
        refresh.afterChange()
    }

    /// Moves a habit's start day. Only allowed while the start is still in the future, and never to a day
    /// before today (SPEC F-03).
    func setStartDay(taskID: UUID, to day: DayKey) throws {
        var task = try existingTask(taskID)
        guard task.type.isHabit, let start = task.startDay else { throw TaskError.wrongType }
        guard start > today else { throw TaskError.notAllowed }
        guard day >= today else { throw TaskError.invalid(.dayInPast) }
        guard day != start else { return }
        task.startDay = day
        var writes: [StoreWrite] = [.task(task)]
        // A habit that hasn't started has one schedule row, and it starts on the start day.
        if var first = try store.schedules(taskID: taskID).first {
            first.effectiveFrom = day
            writes.append(.schedule(first))
        }
        try store.write(writes)
        refresh.afterChange()
    }

    /// Stops a habit and keeps its history (SPEC F-03). The last day becomes yesterday, or today if today
    /// already has a completion or a time entry. A habit that has already ended is left as it is.
    func endHabit(taskID: UUID) throws {
        var task = try existingTask(taskID)
        guard task.type.isHabit else { throw TaskError.wrongType }
        guard !task.hasEnded(today: today, calendar: calendar) else { return }
        let today = today
        let doneToday = try store.completions(taskID: taskID).contains { $0.day == today }
        let loggedToday = try store.timeEntries(taskID: taskID).contains { $0.day == today }
        task.endedOn = doneToday || loggedToday ? today : today.adding(days: -1, in: calendar)
        try store.write([.task(task)])
        refresh.afterChange()
    }

    /// Creates a new habit with the same title, type, schedule, target and length, starting today. The ended
    /// habit keeps its history (SPEC F-03).
    @discardableResult
    func startAgain(taskID: UUID) throws -> TaskValue {
        let old = try existingTask(taskID)
        guard old.type.isHabit else { throw TaskError.wrongType }
        guard let schedule = try store.schedules(taskID: taskID).last else { throw TaskError.notFound }
        return try createHabit(
            type: old.type, title: old.title, timing: schedule.timing, weekdays: schedule.weekdays,
            startDay: today, lengthDays: old.lengthDays, targetMinutes: schedule.targetMinutes,
            allowingEndedPart: true)
    }

    /// Deletes a one-time task (SPEC F-10, F-15).
    func deleteOneTime(taskID: UUID) throws {
        let task = try existingTask(taskID)
        guard task.type == .oneTime else { throw TaskError.wrongType }
        guard Editability.canEditOneTime(task, today: today) else { throw TaskError.notAllowed }
        try deleteEverything(of: task)
    }

    /// Removes a habit with all of its history and stats (SPEC F-03).
    func deleteWithHistory(taskID: UUID) throws {
        let task = try existingTask(taskID)
        guard task.type.isHabit else { throw TaskError.wrongType }
        try deleteEverything(of: task)
    }

    // MARK: Helpers

    /// One-time tasks are editable from today on; habits until they end (SPEC F-04, F-03).
    private func requireEditableSchedule(_ task: TaskValue) throws {
        let editable =
            task.type.isHabit
            ? Editability.canEditHabitSchedule(task, today: today, calendar: calendar)
            : Editability.canEditOneTime(task, today: today)
        if !editable { throw TaskError.notAllowed }
    }

    private func existingTask(_ id: UUID) throws -> TaskValue {
        guard let task = try store.task(id: id) else { throw TaskError.notFound }
        return task
    }

    /// Soft-deletes the task and every row that belongs to it, in one write.
    private func deleteEverything(of task: TaskValue) throws {
        let now = clock.now
        var writes: [StoreWrite] = []
        var deleted = task
        deleted.deletedAt = now
        writes.append(.task(deleted))
        for var schedule in try store.schedules(taskID: task.id) {
            schedule.deletedAt = now
            writes.append(.schedule(schedule))
        }
        for var completion in try store.completions(taskID: task.id) {
            completion.deletedAt = now
            writes.append(.completion(completion))
        }
        for var entry in try store.timeEntries(taskID: task.id) {
            entry.deletedAt = now
            writes.append(.timeEntry(entry))
        }
        try store.write(writes)
        refresh.afterChange()
    }
}
