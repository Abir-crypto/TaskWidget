import Core
import Foundation
import SwiftData
import Testing

@testable import Tempo

struct SwiftDataTaskStoreTests {
    private let clock = TestEnvironment.clock()
    private let store: SwiftDataTaskStore

    init() throws {
        store = try TestEnvironment.store(clock: clock)
    }

    private func habit(title: String = "Read") -> TaskValue {
        TaskValue(title: title, type: .duration, startDay: TestEnvironment.today, createdAt: clock.now)
    }

    // MARK: Tasks

    @Test func taskCreateReadUpdate() throws {
        let saved = try store.save(
            TaskValue(title: "Renew passport", type: .oneTime, date: TestEnvironment.today, createdAt: clock.now))
        #expect(try store.tasks() == [saved])
        #expect(try store.task(id: saved.id) == saved)

        var changed = saved
        changed.title = "Renew the passport"
        try store.save(changed)
        #expect(try store.task(id: saved.id)?.title == "Renew the passport")
        #expect(try store.tasks().count == 1)
    }

    @Test func taskFieldsRoundTrip() throws {
        let task = TaskValue(
            title: "Medicine", type: .progress, startDay: TestEnvironment.today, lengthDays: 30,
            endedOn: DayKey(year: 2026, month: 10, day: 20), createdAt: clock.now)
        try store.save(task)
        let read = try #require(try store.task(id: task.id))
        #expect(read.type == .progress)
        #expect(read.startDay == TestEnvironment.today)
        #expect(read.lengthDays == 30)
        #expect(read.endedOn == DayKey(year: 2026, month: 10, day: 20))
        #expect(read.date == nil)
        #expect(read.createdAt == clock.now)
    }

    @Test func softDeletedTasksNeverAppear() throws {
        let kept = try store.save(habit(title: "Kept"))
        let deleted = try store.save(habit(title: "Deleted"))
        try store.softDeleteTask(id: deleted.id)
        #expect(try store.tasks().map(\.id) == [kept.id])
        #expect(try store.task(id: deleted.id) == nil)
        #expect(try store.loadAll().tasks.map(\.id) == [kept.id])
    }

    @Test func softDeleteKeepsTheRow() throws {
        let task = try store.save(habit())
        clock.advance(by: 60)
        try store.softDeleteTask(id: task.id)
        let id = task.id
        let records = try ModelContext(store.container).fetch(
            FetchDescriptor<SchemaV3.TaskRecord>(predicate: #Predicate { $0.id == id }))
        #expect(records.count == 1)
        #expect(records.first?.deletedAt == clock.now)
        #expect(records.first?.updatedAt == clock.now)
    }

    @Test func tasksAreReadInCreationOrder() throws {
        let first = try store.save(habit(title: "First"))
        clock.advance(by: 1)
        let second = try store.save(
            TaskValue(title: "Second", type: .progress, startDay: TestEnvironment.today, createdAt: clock.now))
        #expect(try store.tasks().map(\.id) == [first.id, second.id])
    }

    // MARK: updated_at

    @Test func everyWriteSetsUpdatedAt() throws {
        let created = try store.save(habit())
        #expect(created.updatedAt == clock.now)

        clock.advance(by: 60)
        var renamed = created
        renamed.title = "Read more"
        let updated = try store.save(renamed)
        #expect(updated.updatedAt == clock.now)
        #expect(try store.task(id: created.id)?.updatedAt == clock.now)
        #expect(try store.task(id: created.id)?.createdAt == created.createdAt)

        clock.advance(by: 60)
        let schedule = try store.save(
            ScheduleValue(
                taskID: created.id, effectiveFrom: TestEnvironment.today, timing: .anytime, weekdays: .all,
                createdAt: clock.now))
        clock.advance(by: 60)
        let resaved = try store.save(schedule)
        #expect(resaved.updatedAt == clock.now)
        #expect(try store.schedules(taskID: created.id).first?.updatedAt == clock.now)

        clock.advance(by: 60)
        let settings = try store.save(SettingsValue.defaults)
        #expect(settings.updatedAt == clock.now)
        #expect(try store.settings()?.updatedAt == clock.now)
    }

    // MARK: Schedules

    @Test(arguments: [Timing.fixed(minute: 750), .part(.evening), .anytime])
    func scheduleTimingsRoundTrip(timing: Timing) throws {
        let task = try store.save(habit())
        let schedule = ScheduleValue(
            taskID: task.id, effectiveFrom: TestEnvironment.today, timing: timing,
            weekdays: [.monday, .wednesday, .friday], targetMinutes: 30, createdAt: clock.now)
        try store.save(schedule)
        let read = try #require(try store.schedules(taskID: task.id).first)
        #expect(read.timing == timing)
        #expect(read.weekdays.rawValue == 21)
        #expect(read.targetMinutes == 30)
        #expect(read.effectiveFrom == TestEnvironment.today)
    }

    @Test func schedulesFilterSortAndSoftDelete() throws {
        let task = try store.save(habit())
        let other = try store.save(habit(title: "Other"))
        let later = try store.save(
            ScheduleValue(
                taskID: task.id, effectiveFrom: DayKey(rawValue: 20_261_008), timing: .anytime, weekdays: .all,
                createdAt: clock.now))
        let earlier = try store.save(
            ScheduleValue(
                taskID: task.id, effectiveFrom: TestEnvironment.today, timing: .anytime, weekdays: .all,
                createdAt: clock.now))
        try store.save(
            ScheduleValue(
                taskID: other.id, effectiveFrom: TestEnvironment.today, timing: .anytime, weekdays: .all,
                createdAt: clock.now))

        #expect(try store.schedules(taskID: task.id).map(\.id) == [earlier.id, later.id])
        #expect(try store.schedules(taskID: nil).count == 3)

        try store.softDeleteSchedule(id: later.id)
        #expect(try store.schedules(taskID: task.id).map(\.id) == [earlier.id])
        #expect(try store.loadAll().schedules.count == 2)
    }

    // MARK: Completions

    @Test func completionsCreateReadUpdateDelete() throws {
        let task = try store.save(
            TaskValue(title: "Medicine", type: .progress, startDay: TestEnvironment.today, createdAt: clock.now))
        let completion = try store.save(
            CompletionValue(taskID: task.id, day: TestEnvironment.today, createdAt: clock.now))
        #expect(try store.completions(taskID: task.id) == [completion])
        #expect(try store.completions(taskID: UUID()).isEmpty)

        var moved = completion
        moved.day = DayKey(rawValue: 20_261_005)
        try store.save(moved)
        #expect(try store.completions(taskID: nil).map(\.day) == [DayKey(rawValue: 20_261_005)])

        try store.softDeleteCompletion(id: completion.id)
        #expect(try store.completions(taskID: nil).isEmpty)
        #expect(try store.loadAll().completions.isEmpty)
    }

    // MARK: Time entries

    @Test func timeEntriesCreateReadUpdateDelete() throws {
        let task = try store.save(habit())
        let entry = try store.save(
            TimeEntryValue(
                taskID: task.id, day: TestEnvironment.today, seconds: 1_200, source: .timer, createdAt: clock.now))
        #expect(try store.timeEntries(taskID: task.id) == [entry])

        var longer = entry
        longer.seconds = 1_800
        longer.source = .manual
        try store.save(longer)
        let read = try #require(try store.timeEntries(taskID: nil).first)
        #expect(read.seconds == 1_800)
        #expect(read.source == .manual)

        try store.softDeleteTimeEntry(id: entry.id)
        #expect(try store.timeEntries(taskID: task.id).isEmpty)
        #expect(try store.loadAll().timeEntries.isEmpty)
    }

    @Test func timeEntriesNeedSeconds() throws {
        let task = try store.save(habit())
        #expect(throws: StorageError.self) {
            try store.save(
                TimeEntryValue(
                    taskID: task.id, day: TestEnvironment.today, seconds: 0, source: .manual, createdAt: clock.now))
        }
        #expect(try store.timeEntries(taskID: nil).isEmpty)
    }

    // MARK: Settings

    @Test func settingsRowStartsMissingThenRoundTrips() throws {
        #expect(try store.settings() == nil)
        var settings = SettingsValue.defaults
        settings.parts = PartSettings(morningStart: 420, noonStart: 690, eveningStart: 1080, nightStart: 1320)
        settings.notifyRecap = false
        settings.fixedLead = 15
        settings.hideLockScreenTitles = true
        settings.tintColor = .preset(.teal)
        settings.appearance = .dark
        let saved = try store.save(settings)
        #expect(try store.settings() == saved)
        #expect(try store.settings()?.tintColor == .preset(.teal))
        #expect(try store.settings()?.appearance == .dark)

        var custom = saved
        custom.tintColor = .custom(red: 30, green: 144, blue: 255)
        try store.save(custom)
        #expect(try store.settings()?.tintColor == .custom(red: 30, green: 144, blue: 255))

        var again = saved
        again.endingSoonLead = 45
        try store.save(again)
        #expect(try store.settings()?.endingSoonLead == 45)
        let rows = try ModelContext(store.container).fetch(FetchDescriptor<SchemaV3.SettingsRecord>())
        #expect(rows.count == 1)
        #expect(rows.first?.appearance == "dark")
    }

    // MARK: Batch writes

    @Test func batchWritesAreAllOrNothing() throws {
        let task = habit()
        let schedule = ScheduleValue(
            taskID: task.id, effectiveFrom: TestEnvironment.today, timing: .anytime, weekdays: .all,
            createdAt: clock.now)
        let badEntry = TimeEntryValue(
            taskID: task.id, day: TestEnvironment.today, seconds: 0, source: .manual, createdAt: clock.now)
        #expect(throws: StorageError.self) {
            try store.write([.task(task), .schedule(schedule), .timeEntry(badEntry)])
        }
        #expect(try store.tasks().isEmpty)
        #expect(try store.schedules(taskID: nil).isEmpty)

        clock.advance(by: 60)
        try store.write([.task(task), .schedule(schedule)])
        #expect(try store.tasks().first?.updatedAt == clock.now)
        #expect(try store.schedules(taskID: task.id).first?.updatedAt == clock.now)
    }

    // MARK: Everything

    @Test func loadAllReadsEveryTable() throws {
        let task = try store.save(habit())
        try store.save(
            ScheduleValue(
                taskID: task.id, effectiveFrom: TestEnvironment.today, timing: .anytime, weekdays: .all,
                targetMinutes: 30, createdAt: clock.now))
        try store.save(
            TimeEntryValue(
                taskID: task.id, day: TestEnvironment.today, seconds: 60, source: .manual, createdAt: clock.now))
        let medicine = try store.save(
            TaskValue(title: "Medicine", type: .progress, startDay: TestEnvironment.today, createdAt: clock.now))
        try store.save(CompletionValue(taskID: medicine.id, day: TestEnvironment.today, createdAt: clock.now))

        let data = try store.loadAll()
        #expect(data.tasks.count == 2)
        #expect(data.schedules.count == 1)
        #expect(data.completions.count == 1)
        #expect(data.timeEntries.count == 1)
    }
}
