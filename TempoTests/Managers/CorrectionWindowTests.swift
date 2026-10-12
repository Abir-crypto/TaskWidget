import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-41, §5.11: yesterday can be corrected until today's Afternoon starts. Wednesday 7 Oct is "today" here,
/// and Tuesday 6 Oct is yesterday.
@MainActor
struct CorrectionWindowTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let tuesday = DayKey(year: 2026, month: 10, day: 6)
    private let monday = DayKey(year: 2026, month: 10, day: 5)

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func wednesday(_ hour: Int, _ minute: Int = 0) {
        clock.now = TestEnvironment.date(2026, 10, 7, hour, minute)
    }

    /// Monday and Tuesday: a one-time task each day, a progress habit and a duration habit from Monday.
    private func makeTasks() throws -> (call: TaskValue, monday: TaskValue, medicine: TaskValue, read: TaskValue) {
        clock.now = TestEnvironment.date(2026, 10, 5, 7)
        let earlier = try tasks.createOneTime(title: "Monday call", date: monday, timing: .part(.morning))
        let medicine = try tasks.createHabit(
            type: .progress, title: "Medicine", timing: .part(.morning), weekdays: .all, startDay: monday,
            lengthDays: nil, targetMinutes: nil)
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: .all, startDay: monday,
            lengthDays: nil, targetMinutes: 30)
        let call = try tasks.createOneTime(title: "Call", date: tuesday, timing: .part(.morning))
        return (call, earlier, medicine, read)
    }

    // MARK: Managers

    @Test func yesterdayCanBeCompletedUndoneAndGivenTimeDuringTheWindow() throws {
        let made = try makeTasks()
        wednesday(11, 59)
        try tasks.complete(taskID: made.call.id, day: tuesday)
        try tasks.complete(taskID: made.medicine.id, day: tuesday)
        try tasks.undoCompletion(taskID: made.medicine.id, day: tuesday)
        let entry = try tasks.logTime(taskID: made.read.id, minutes: 20, day: tuesday)
        #expect(entry.day == tuesday)
        #expect(try store.completions(taskID: made.call.id).map(\.day) == [tuesday])
        #expect(try store.completions(taskID: made.medicine.id).isEmpty)
        try tasks.deleteTimeEntry(id: entry.id)
        #expect(try store.timeEntries(taskID: made.read.id).isEmpty)
    }

    @Test func nothingElseChangesOnYesterday() throws {
        let made = try makeTasks()
        wednesday(9)
        #expect(throws: TaskError.notAllowed) { try tasks.moveToNextDay(taskID: made.call.id) }
        #expect(throws: TaskError.notAllowed) { try tasks.rename(taskID: made.call.id, to: "New") }
        #expect(throws: TaskError.notAllowed) { try tasks.deleteOneTime(taskID: made.call.id) }
        // The day before yesterday is final, even during the window.
        #expect(throws: TaskError.notAllowed) { try tasks.complete(taskID: made.monday.id, day: monday) }
        #expect(throws: TaskError.notAllowed) { try tasks.logTime(taskID: made.read.id, minutes: 20, day: monday) }
    }

    @Test func yesterdayIsFinalOnceAfternoonStarts() throws {
        let made = try makeTasks()
        wednesday(9)
        let entry = try tasks.logTime(taskID: made.read.id, minutes: 20, day: tuesday)
        wednesday(12)
        #expect(throws: TaskError.notAllowed) { try tasks.complete(taskID: made.call.id, day: tuesday) }
        #expect(throws: TaskError.notAllowed) { try tasks.logTime(taskID: made.read.id, minutes: 20, day: tuesday) }
        #expect(throws: TaskError.notAllowed) { try tasks.deleteTimeEntry(id: entry.id) }
    }

    @Test func theWindowEndsAtAfternoonsStartAsSetNow() throws {
        let made = try makeTasks()
        var settings = SettingsValue.defaults
        settings.parts = settings.parts.setting(.noon, to: 780)
        try store.save(settings)
        wednesday(12, 59)
        try tasks.complete(taskID: made.call.id, day: tuesday)
        wednesday(13)
        #expect(throws: TaskError.notAllowed) { try tasks.undoCompletion(taskID: made.call.id, day: tuesday) }
    }

    /// Correcting yesterday changes the stats at once, because they're computed (SPEC §5.7).
    @Test func correctingYesterdayUpdatesStreaksAndTotals() throws {
        let made = try makeTasks()
        wednesday(9)
        let before = StatsCalculator(snapshot: try tasks.snapshot(), now: clock.now)
        #expect(before.streak(of: made.medicine).current == 0)
        try tasks.complete(taskID: made.medicine.id, day: tuesday)
        try tasks.logTime(taskID: made.read.id, minutes: 30, day: tuesday)
        let after = StatsCalculator(snapshot: try tasks.snapshot(), now: clock.now)
        #expect(after.streak(of: made.medicine).current == 1)
        let snapshot = try tasks.snapshot()
        #expect(snapshot.activity.minutes(taskID: made.read.id, day: tuesday) == 30)
        #expect(
            snapshot.status(of: try #require(snapshot.engine.occurrence(of: made.read, on: tuesday)), now: clock.now)
                == .done)
    }

    // MARK: Screens

    @Test func todayShowsTheWindowOnYesterday() throws {
        let made = try makeTasks()
        wednesday(9)
        let model = TodayViewModel(tasks: tasks, clock: clock)
        model.load()
        model.select(tuesday)
        let plan = try #require(model.plan(at: clock.now))
        let call = try #require(plan.items.first { $0.task.id == made.call.id })
        let read = try #require(plan.items.first { $0.task.id == made.read.id })
        #expect(model.correctionClosingMinute(at: clock.now) == 720)
        #expect(model.canComplete(call))
        #expect(model.canLogTime(read))
        #expect(!model.canStartTimer(read))
        #expect(!model.canMove(call))
        #expect(!model.canEditOrDelete(call))
        model.select(monday)
        #expect(model.correctionClosingMinute(at: clock.now) == nil)

        wednesday(12)
        model.select(tuesday)
        #expect(model.correctionClosingMinute(at: clock.now) == nil)
        #expect(!model.canComplete(call))
        #expect(!model.canLogTime(read))
    }

    @Test func missedShowsYesterdayWithTodayUntilTheWindowCloses() throws {
        let made = try makeTasks()
        wednesday(9)
        let model = MissedViewModel(tasks: tasks, clock: clock)
        model.load()
        #expect(Set(model.yesterdayItems.map(\.occurrence.task.id)) == [made.call.id, made.medicine.id, made.read.id])
        #expect(!model.earlierGroups.contains { $0.day == tuesday })
        #expect(model.earlierGroups.contains { $0.day == monday })
        let call = try #require(model.yesterdayItems.first { $0.occurrence.task.id == made.call.id })
        let read = try #require(model.yesterdayItems.first { $0.occurrence.task.id == made.read.id })
        #expect(model.canMarkDone(call))
        #expect(model.canLogTime(read))
        #expect(!model.canMove(call))
        #expect(!model.needsReload)

        wednesday(12)
        #expect(model.needsReload)
        model.load()
        #expect(model.yesterdayItems.isEmpty)
        #expect(model.earlierGroups.contains { $0.day == tuesday })
        #expect(!model.needsReload)
    }

    @Test func logTimeSavesToYesterday() throws {
        let made = try makeTasks()
        wednesday(9)
        let model = LogTimeViewModel(tasks: tasks, taskID: made.read.id, day: tuesday)
        model.load()
        #expect(model.isForYesterday)
        #expect(model.canLog)
        model.minutes = 25
        #expect(model.save())
        #expect(try store.timeEntries(taskID: made.read.id).map(\.day) == [tuesday])
    }

    @Test func historyAllowsMarkNotDoneDuringTheWindow() throws {
        let made = try makeTasks()
        wednesday(9)
        try tasks.complete(taskID: made.call.id, day: tuesday)
        let model = HistoryViewModel(tasks: tasks, clock: clock)
        model.load()
        let item = try #require(model.completedGroups.flatMap(\.tasks).first { $0.task.id == made.call.id })
        #expect(item.canUndo)
        wednesday(12)
        model.load()
        let later = try #require(model.completedGroups.flatMap(\.tasks).first { $0.task.id == made.call.id })
        #expect(!later.canUndo)
    }

    @Test func habitDetailListsYesterdaysEntriesDuringTheWindow() throws {
        let made = try makeTasks()
        wednesday(9)
        let entry = try tasks.logTime(taskID: made.read.id, minutes: 20, day: tuesday)
        let model = HabitDetailViewModel(tasks: tasks, clock: clock, taskID: made.read.id)
        model.load()
        #expect(model.yesterdaysEntries.map(\.id) == [entry.id])
        #expect(model.canDelete(entry))
        wednesday(12)
        model.load()
        #expect(model.yesterdaysEntries.isEmpty)
        #expect(!model.canDelete(entry))
    }
}
