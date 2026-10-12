import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC F-05 through `TaskManager`: Log time and deleting entries.
@MainActor
struct TimeLoggingTests {
    private let clock = TestEnvironment.clock(hour: 10)
    private let store: SwiftDataTaskStore
    private let manager: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        manager = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func read(start: DayKey? = nil, weekdays: Weekdays = .all) throws -> TaskValue {
        try manager.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: weekdays,
            startDay: start ?? manager.today, lengthDays: nil, targetMinutes: 30)
    }

    @Test func logTimeAddsAManualEntryToToday() throws {
        let task = try read()
        let entry = try manager.logTime(taskID: task.id, minutes: 20)
        #expect(entry.day == day(6))
        #expect(entry.seconds == 1_200)
        #expect(entry.source == .manual)
        try manager.logTime(taskID: task.id, minutes: 15)
        let snapshot = try manager.snapshot()
        #expect(snapshot.activity.minutes(taskID: task.id, day: day(6)) == 35)
        let occurrence = try #require(snapshot.engine.occurrence(of: task, on: day(6)))
        #expect(snapshot.status(of: occurrence, now: clock.now) == .done)
    }

    @Test func logTimeWorksOnUnscheduledDays() throws {
        let task = try read(weekdays: [.monday])
        try manager.logTime(taskID: task.id, minutes: 10)
        #expect(try store.timeEntries(taskID: task.id).count == 1)
    }

    @Test func entriesCantGoToFutureOrPastDays() throws {
        let future = try read(start: day(8))
        #expect(throws: TaskError.notAllowed) { try manager.logTime(taskID: future.id, minutes: 10) }

        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let ended = try read()
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.endHabit(taskID: ended.id)
        #expect(throws: TaskError.notAllowed) { try manager.logTime(taskID: ended.id, minutes: 10) }
        #expect(try store.timeEntries(taskID: nil).isEmpty)
    }

    @Test func logTimeUsesFiveMinuteSteps() throws {
        let task = try read()
        #expect(throws: TaskError.invalid(.invalidLogTime)) { try manager.logTime(taskID: task.id, minutes: 3) }
        #expect(throws: TaskError.invalid(.invalidLogTime)) { try manager.logTime(taskID: task.id, minutes: 485) }
        #expect(throws: TaskError.invalid(.invalidLogTime)) { try manager.logTime(taskID: task.id, minutes: 12) }
    }

    @Test func onlyDurationHabitsReceiveTime() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .anytime)
        #expect(throws: TaskError.wrongType) { try manager.logTime(taskID: task.id, minutes: 10) }
    }

    @Test func todaysEntriesCanBeDeletedButPastOnesCant() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let task = try read()
        let yesterday = try manager.logTime(taskID: task.id, minutes: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 13)  // after the correction window (SPEC §5.11)
        let today = try manager.logTime(taskID: task.id, minutes: 10)
        try manager.deleteTimeEntry(id: today.id)
        #expect(throws: TaskError.notAllowed) { try manager.deleteTimeEntry(id: yesterday.id) }
        #expect(try store.timeEntries(taskID: task.id).map(\.id) == [yesterday.id])
    }
}
