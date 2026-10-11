import Core
import Foundation
import SwiftData

/// `TaskStore` on SwiftData (ios.md §6).
///
/// Every call makes a fresh `ModelContext`, so it always sees writes made by the other process (app or
/// widget extension). Records are converted to `Core` values here and never leave this file.
final class SwiftDataTaskStore: TaskStore {
    typealias TaskRecord = SchemaV2.TaskRecord
    typealias ScheduleRecord = SchemaV2.ScheduleRecord
    typealias CompletionRecord = SchemaV2.CompletionRecord
    typealias TimeEntryRecord = SchemaV2.TimeEntryRecord
    typealias SettingsRecord = SchemaV2.SettingsRecord

    /// The settings table's one fixed id (SPEC §4.5).
    static let settingsID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))

    let container: ModelContainer
    private let clock: any Clock

    init(container: ModelContainer, clock: any Clock) {
        self.container = container
        self.clock = clock
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    // MARK: Everything

    func loadAll() throws -> TaskData {
        let context = makeContext()
        return TaskData(
            tasks: try fetchTasks(in: context),
            schedules: try fetchSchedules(taskID: nil, in: context),
            completions: try fetchCompletions(taskID: nil, in: context),
            timeEntries: try fetchTimeEntries(taskID: nil, in: context)
        )
    }

    // MARK: Batch writes

    /// Applies every write in one context and one save, so either all of them land or none do.
    /// Each row's `updatedAt` is set to the clock's now.
    func write(_ writes: [StoreWrite]) throws {
        try write(writes, at: clock.now)
    }

    private func write(_ writes: [StoreWrite], at now: Date) throws {
        guard !writes.isEmpty else { return }
        let context = makeContext()
        for write in writes {
            switch write {
            case .task(var task):
                task.updatedAt = now
                try apply(task, in: context)
            case .schedule(var schedule):
                schedule.updatedAt = now
                try apply(schedule, in: context)
            case .completion(var completion):
                completion.updatedAt = now
                try apply(completion, in: context)
            case .timeEntry(var entry):
                entry.updatedAt = now
                try apply(entry, in: context)
            }
        }
        try context.save()
    }

    // MARK: Tasks

    func tasks() throws -> [TaskValue] {
        try fetchTasks(in: makeContext())
    }

    func task(id: UUID) throws -> TaskValue? {
        let descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id && $0.deletedAt == nil })
        return try makeContext().fetch(descriptor).first.flatMap(Self.value(of:))
    }

    @discardableResult
    func save(_ task: TaskValue) throws -> TaskValue {
        let now = clock.now
        try write([.task(task)], at: now)
        var stored = task
        stored.updatedAt = now
        return stored
    }

    private func apply(_ task: TaskValue, in context: ModelContext) throws {
        let id = task.id
        let existing = try context.fetch(FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? TaskRecord()
        if existing == nil { context.insert(record) }
        record.id = task.id
        record.title = task.title
        record.type = task.type.rawValue
        record.date = task.date?.rawValue
        record.startDay = task.startDay?.rawValue
        record.lengthDays = task.lengthDays
        record.endedOn = task.endedOn?.rawValue
        record.createdAt = task.createdAt
        record.updatedAt = task.updatedAt
        record.deletedAt = task.deletedAt
    }

    func softDeleteTask(id: UUID) throws {
        let context = makeContext()
        let descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id && $0.deletedAt == nil })
        guard let record = try context.fetch(descriptor).first else { return }
        let now = clock.now
        record.deletedAt = now
        record.updatedAt = now
        try context.save()
    }

    private func fetchTasks(in context: ModelContext) throws -> [TaskValue] {
        let descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).compactMap(Self.value(of:))
    }

    private static func value(of record: TaskRecord) -> TaskValue? {
        guard let type = TaskType(rawValue: record.type) else {
            Log.storage.error("Skipping task \(record.id) with unknown type \(record.type, privacy: .public)")
            return nil
        }
        return TaskValue(
            id: record.id,
            title: record.title,
            type: type,
            date: record.date.map(DayKey.init(rawValue:)),
            startDay: record.startDay.map(DayKey.init(rawValue:)),
            lengthDays: record.lengthDays,
            endedOn: record.endedOn.map(DayKey.init(rawValue:)),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: record.deletedAt
        )
    }

    // MARK: Schedules

    func schedules(taskID: UUID?) throws -> [ScheduleValue] {
        try fetchSchedules(taskID: taskID, in: makeContext())
    }

    @discardableResult
    func save(_ schedule: ScheduleValue) throws -> ScheduleValue {
        let now = clock.now
        try write([.schedule(schedule)], at: now)
        var stored = schedule
        stored.updatedAt = now
        return stored
    }

    private func apply(_ schedule: ScheduleValue, in context: ModelContext) throws {
        let id = schedule.id
        let existing = try context.fetch(FetchDescriptor<ScheduleRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? ScheduleRecord()
        if existing == nil { context.insert(record) }
        record.id = schedule.id
        record.taskID = schedule.taskID
        record.effectiveFrom = schedule.effectiveFrom.rawValue
        record.timing = schedule.timing.kind.rawValue
        record.fixedMinute = schedule.timing.fixedMinute
        record.part = schedule.timing.part?.rawValue
        record.weekdays = schedule.weekdays.rawValue
        record.targetMinutes = schedule.targetMinutes
        record.createdAt = schedule.createdAt
        record.updatedAt = schedule.updatedAt
        record.deletedAt = schedule.deletedAt
    }

    func softDeleteSchedule(id: UUID) throws {
        let context = makeContext()
        let descriptor = FetchDescriptor<ScheduleRecord>(predicate: #Predicate { $0.id == id && $0.deletedAt == nil })
        guard let record = try context.fetch(descriptor).first else { return }
        let now = clock.now
        record.deletedAt = now
        record.updatedAt = now
        try context.save()
    }

    private func fetchSchedules(taskID: UUID?, in context: ModelContext) throws -> [ScheduleValue] {
        let predicate: Predicate<ScheduleRecord>
        if let taskID {
            predicate = #Predicate { $0.taskID == taskID && $0.deletedAt == nil }
        } else {
            predicate = #Predicate { $0.deletedAt == nil }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.effectiveFrom)])
        return try context.fetch(descriptor).compactMap(Self.value(of:))
    }

    private static func value(of record: ScheduleRecord) -> ScheduleValue? {
        guard let kind = TimingKind(rawValue: record.timing),
            let timing = Timing(kind: kind, fixedMinute: record.fixedMinute, part: record.part.flatMap(DayPart.init))
        else {
            Log.storage.error("Skipping schedule \(record.id) with invalid timing \(record.timing, privacy: .public)")
            return nil
        }
        return ScheduleValue(
            id: record.id,
            taskID: record.taskID,
            effectiveFrom: DayKey(rawValue: record.effectiveFrom),
            timing: timing,
            weekdays: Weekdays(rawValue: record.weekdays),
            targetMinutes: record.targetMinutes,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: record.deletedAt
        )
    }

    // MARK: Completions

    func completions(taskID: UUID?) throws -> [CompletionValue] {
        try fetchCompletions(taskID: taskID, in: makeContext())
    }

    @discardableResult
    func save(_ completion: CompletionValue) throws -> CompletionValue {
        let now = clock.now
        try write([.completion(completion)], at: now)
        var stored = completion
        stored.updatedAt = now
        return stored
    }

    private func apply(_ completion: CompletionValue, in context: ModelContext) throws {
        let id = completion.id
        let existing = try context.fetch(FetchDescriptor<CompletionRecord>(predicate: #Predicate { $0.id == id }))
            .first
        let record = existing ?? CompletionRecord()
        if existing == nil { context.insert(record) }
        record.id = completion.id
        record.taskID = completion.taskID
        record.day = completion.day.rawValue
        record.createdAt = completion.createdAt
        record.updatedAt = completion.updatedAt
        record.deletedAt = completion.deletedAt
    }

    func softDeleteCompletion(id: UUID) throws {
        let context = makeContext()
        let descriptor = FetchDescriptor<CompletionRecord>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil })
        guard let record = try context.fetch(descriptor).first else { return }
        let now = clock.now
        record.deletedAt = now
        record.updatedAt = now
        try context.save()
    }

    private func fetchCompletions(taskID: UUID?, in context: ModelContext) throws -> [CompletionValue] {
        let predicate: Predicate<CompletionRecord>
        if let taskID {
            predicate = #Predicate { $0.taskID == taskID && $0.deletedAt == nil }
        } else {
            predicate = #Predicate { $0.deletedAt == nil }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.day)])
        return try context.fetch(descriptor).map { record in
            CompletionValue(
                id: record.id,
                taskID: record.taskID,
                day: DayKey(rawValue: record.day),
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                deletedAt: record.deletedAt
            )
        }
    }

    // MARK: Time entries

    func timeEntries(taskID: UUID?) throws -> [TimeEntryValue] {
        try fetchTimeEntries(taskID: taskID, in: makeContext())
    }

    @discardableResult
    func save(_ entry: TimeEntryValue) throws -> TimeEntryValue {
        let now = clock.now
        try write([.timeEntry(entry)], at: now)
        var stored = entry
        stored.updatedAt = now
        return stored
    }

    private func apply(_ entry: TimeEntryValue, in context: ModelContext) throws {
        guard entry.seconds > 0 else { throw StorageError.invalidValue("A time entry needs more than 0 seconds.") }
        let id = entry.id
        let existing = try context.fetch(FetchDescriptor<TimeEntryRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? TimeEntryRecord()
        if existing == nil { context.insert(record) }
        record.id = entry.id
        record.taskID = entry.taskID
        record.day = entry.day.rawValue
        record.seconds = entry.seconds
        record.source = entry.source.rawValue
        record.createdAt = entry.createdAt
        record.updatedAt = entry.updatedAt
        record.deletedAt = entry.deletedAt
    }

    func softDeleteTimeEntry(id: UUID) throws {
        let context = makeContext()
        let descriptor = FetchDescriptor<TimeEntryRecord>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil })
        guard let record = try context.fetch(descriptor).first else { return }
        let now = clock.now
        record.deletedAt = now
        record.updatedAt = now
        try context.save()
    }

    private func fetchTimeEntries(taskID: UUID?, in context: ModelContext) throws -> [TimeEntryValue] {
        let predicate: Predicate<TimeEntryRecord>
        if let taskID {
            predicate = #Predicate { $0.taskID == taskID && $0.deletedAt == nil }
        } else {
            predicate = #Predicate { $0.deletedAt == nil }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).compactMap { record in
            guard let source = TimeEntrySource(rawValue: record.source) else {
                Log.storage.error(
                    "Skipping time entry \(record.id) with unknown source \(record.source, privacy: .public)")
                return nil
            }
            return TimeEntryValue(
                id: record.id,
                taskID: record.taskID,
                day: DayKey(rawValue: record.day),
                seconds: record.seconds,
                source: source,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                deletedAt: record.deletedAt
            )
        }
    }

    // MARK: Settings

    func settings() throws -> SettingsValue? {
        let id = Self.settingsID
        let descriptor = FetchDescriptor<SettingsRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try makeContext().fetch(descriptor).first else { return nil }
        return SettingsValue(
            parts: PartSettings(
                morningStart: record.morningStart,
                noonStart: record.noonStart,
                eveningStart: record.eveningStart,
                nightStart: record.nightStart
            ),
            notifyPartStart: record.notifyPartStart,
            notifyEndingSoon: record.notifyEndingSoon,
            endingSoonLead: record.endingSoonLead,
            notifyFixed: record.notifyFixed,
            fixedLead: record.fixedLead,
            notifyRecap: record.notifyRecap,
            recapMinute: record.recapMinute,
            notifyTimer: record.notifyTimer,
            timerAlertMinutes: record.timerAlertMinutes,
            hideLockScreenTitles: record.hideLockScreenTitles,
            tintColor: ThemeColor(storedValue: record.tintColor),
            updatedAt: record.updatedAt
        )
    }

    @discardableResult
    func save(_ settings: SettingsValue) throws -> SettingsValue {
        var stored = settings
        stored.updatedAt = clock.now
        let context = makeContext()
        let id = Self.settingsID
        let existing = try context.fetch(FetchDescriptor<SettingsRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? SettingsRecord()
        if existing == nil { context.insert(record) }
        record.id = id
        record.morningStart = stored.parts.morningStart
        record.noonStart = stored.parts.noonStart
        record.eveningStart = stored.parts.eveningStart
        record.nightStart = stored.parts.nightStart
        record.notifyPartStart = stored.notifyPartStart
        record.notifyEndingSoon = stored.notifyEndingSoon
        record.endingSoonLead = stored.endingSoonLead
        record.notifyFixed = stored.notifyFixed
        record.fixedLead = stored.fixedLead
        record.notifyRecap = stored.notifyRecap
        record.recapMinute = stored.recapMinute
        record.notifyTimer = stored.notifyTimer
        record.timerAlertMinutes = stored.timerAlertMinutes
        record.hideLockScreenTitles = stored.hideLockScreenTitles
        record.tintColor = stored.tintColor.storedValue
        record.updatedAt = clock.now
        try context.save()
        return stored
    }
}
