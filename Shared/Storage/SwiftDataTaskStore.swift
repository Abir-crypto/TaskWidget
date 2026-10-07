import Core
import Foundation
import SwiftData

/// `TaskStore` on SwiftData (ios.md §6).
///
/// Every call makes a fresh `ModelContext`, so it always sees writes made by the other process (app or
/// widget extension). Records are converted to `Core` values here and never leave this file.
final class SwiftDataTaskStore: TaskStore {
    typealias TaskRecord = SchemaV1.TaskRecord
    typealias ScheduleRecord = SchemaV1.ScheduleRecord
    typealias CompletionRecord = SchemaV1.CompletionRecord
    typealias TimeEntryRecord = SchemaV1.TimeEntryRecord
    typealias SettingsRecord = SchemaV1.SettingsRecord

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
        var stored = task
        stored.updatedAt = clock.now
        let context = makeContext()
        let id = task.id
        let existing = try context.fetch(FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? TaskRecord()
        if existing == nil { context.insert(record) }
        record.id = stored.id
        record.title = stored.title
        record.type = stored.type.rawValue
        record.date = stored.date?.rawValue
        record.startDay = stored.startDay?.rawValue
        record.lengthDays = stored.lengthDays
        record.endedOn = stored.endedOn?.rawValue
        record.createdAt = stored.createdAt
        record.updatedAt = stored.updatedAt
        record.deletedAt = stored.deletedAt
        try context.save()
        return stored
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
        var stored = schedule
        stored.updatedAt = clock.now
        let context = makeContext()
        let id = schedule.id
        let existing = try context.fetch(FetchDescriptor<ScheduleRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? ScheduleRecord()
        if existing == nil { context.insert(record) }
        record.id = stored.id
        record.taskID = stored.taskID
        record.effectiveFrom = stored.effectiveFrom.rawValue
        record.timing = stored.timing.kind.rawValue
        record.fixedMinute = stored.timing.fixedMinute
        record.part = stored.timing.part?.rawValue
        record.weekdays = stored.weekdays.rawValue
        record.targetMinutes = stored.targetMinutes
        record.createdAt = stored.createdAt
        record.updatedAt = stored.updatedAt
        record.deletedAt = stored.deletedAt
        try context.save()
        return stored
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
        var stored = completion
        stored.updatedAt = clock.now
        let context = makeContext()
        let id = completion.id
        let existing = try context.fetch(FetchDescriptor<CompletionRecord>(predicate: #Predicate { $0.id == id }))
            .first
        let record = existing ?? CompletionRecord()
        if existing == nil { context.insert(record) }
        record.id = stored.id
        record.taskID = stored.taskID
        record.day = stored.day.rawValue
        record.createdAt = stored.createdAt
        record.updatedAt = stored.updatedAt
        record.deletedAt = stored.deletedAt
        try context.save()
        return stored
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
        guard entry.seconds > 0 else { throw StorageError.invalidValue("A time entry needs more than 0 seconds.") }
        var stored = entry
        stored.updatedAt = clock.now
        let context = makeContext()
        let id = entry.id
        let existing = try context.fetch(FetchDescriptor<TimeEntryRecord>(predicate: #Predicate { $0.id == id })).first
        let record = existing ?? TimeEntryRecord()
        if existing == nil { context.insert(record) }
        record.id = stored.id
        record.taskID = stored.taskID
        record.day = stored.day.rawValue
        record.seconds = stored.seconds
        record.source = stored.source.rawValue
        record.createdAt = stored.createdAt
        record.updatedAt = stored.updatedAt
        record.deletedAt = stored.deletedAt
        try context.save()
        return stored
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
        record.updatedAt = clock.now
        try context.save()
        return stored
    }
}
