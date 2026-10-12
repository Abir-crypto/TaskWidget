import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TaskManagerTests {
    private let clock = TestEnvironment.clock(hour: 10)
    private let store: SwiftDataTaskStore
    private let manager: TaskManager
    private var calendar: Calendar { TestEnvironment.calendar }

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        manager = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func habit(
        type: TaskType = .progress, weekdays: Weekdays = .all, start: DayKey? = nil, length: Int? = nil,
        target: Int? = nil
    ) throws -> TaskValue {
        try manager.createHabit(
            type: type, title: "Habit", timing: .part(.evening), weekdays: weekdays,
            startDay: start ?? manager.today, lengthDays: length,
            targetMinutes: type == .duration ? (target ?? 30) : nil)
    }

    // MARK: Create

    @Test func createsAOneTimeTaskWithOneScheduleRow() throws {
        let task = try manager.createOneTime(title: "  Renew passport ", date: day(8), timing: .fixed(minute: 750))
        #expect(task.title == "Renew passport")
        let schedules = try store.schedules(taskID: task.id)
        #expect(schedules.count == 1)
        #expect(schedules.first?.effectiveFrom == .distantPast)
        #expect(schedules.first?.weekdays == Weekdays.none)
        #expect(schedules.first?.timing == .fixed(minute: 750))
        #expect(try manager.engine().occurrence(of: task, on: day(8)) != nil)
    }

    @Test func createsHabitsOfEachType() throws {
        let progress = try habit(type: .progress, weekdays: [.monday, .wednesday, .friday])
        let duration = try habit(type: .duration, target: 45)
        #expect(progress.startDay == manager.today)
        #expect(try store.schedules(taskID: progress.id).first?.weekdays.rawValue == 21)
        #expect(try store.schedules(taskID: duration.id).first?.targetMinutes == 45)
        #expect(try store.schedules(taskID: duration.id).first?.effectiveFrom == manager.today)
    }

    @Test func rejectsInvalidInput() throws {
        #expect(throws: TaskError.invalid(.emptyTitle)) {
            try manager.createOneTime(title: "  ", date: manager.today, timing: .anytime)
        }
        #expect(throws: TaskError.invalid(.dayInPast)) {
            try manager.createOneTime(title: "Late", date: day(5), timing: .anytime)
        }
        #expect(throws: TaskError.invalid(.noWeekdays)) {
            try habit(weekdays: .none)
        }
        #expect(throws: TaskError.invalid(.dayInPast)) {
            try habit(start: day(5))
        }
        #expect(throws: TaskError.invalid(.invalidTarget)) {
            try habit(type: .duration, target: 3)
        }
        #expect(throws: TaskError.invalid(.invalidLength)) {
            try habit(length: 400)
        }
        #expect(throws: TaskError.wrongType) {
            try manager.createHabit(
                type: .oneTime, title: "No", timing: .anytime, weekdays: .all, startDay: manager.today, lengthDays: nil,
                targetMinutes: nil)
        }
        #expect(try store.tasks().isEmpty)
    }

    // MARK: Schedule history

    @Test func weekdayEditOnWednesdayKeepsEarlierDays() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)  // Thu 1 Oct
        let task = try habit(weekdays: .all)
        clock.now = TestEnvironment.date(2026, 10, 7, 9)  // Wed 7 Oct
        try manager.updateSchedule(taskID: task.id, timing: .part(.evening), weekdays: [.thursday], targetMinutes: nil)

        let engine = try manager.engine()
        #expect(engine.occurrence(of: task, on: day(5)) != nil)  // Mon: old weekdays
        #expect(engine.occurrence(of: task, on: day(6)) != nil)  // Tue: old weekdays
        #expect(engine.occurrence(of: task, on: day(7)) == nil)  // Wed: new weekdays
        #expect(engine.occurrence(of: task, on: day(8)) != nil)  // Thu
        #expect(try store.schedules(taskID: task.id).map(\.effectiveFrom) == [day(1), day(7)])
    }

    @Test func twoEditsOnOneDayLeaveOneRowForThatDay() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit(type: .duration, target: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.updateSchedule(taskID: task.id, timing: .part(.evening), weekdays: .all, targetMinutes: 45)
        try manager.updateSchedule(taskID: task.id, timing: .part(.noon), weekdays: .all, targetMinutes: 60)
        let rows = try store.schedules(taskID: task.id)
        #expect(rows.map(\.effectiveFrom) == [day(1), day(6)])
        #expect(rows.last?.targetMinutes == 60)
        #expect(rows.last?.timing == .part(.noon))
        #expect(rows.first?.targetMinutes == 30)
    }

    @Test func editingAHabitThatHasNotStartedUpdatesItsFirstRow() throws {
        let task = try habit(start: day(10))
        try manager.updateSchedule(
            taskID: task.id, timing: .fixed(minute: 480), weekdays: [.saturday], targetMinutes: nil)
        let rows = try store.schedules(taskID: task.id)
        #expect(rows.count == 1)
        #expect(rows.first?.effectiveFrom == day(10))
        #expect(rows.first?.weekdays == [.saturday])
        #expect(rows.first?.timing == .fixed(minute: 480))
    }

    @Test func unchangedScheduleWritesNoRow() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit()
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.updateSchedule(taskID: task.id, timing: .part(.evening), weekdays: .all, targetMinutes: nil)
        #expect(try store.schedules(taskID: task.id).count == 1)
    }

    @Test func oneTimeScheduleChangesInPlace() throws {
        let task = try manager.createOneTime(title: "Call", date: manager.today, timing: .anytime)
        try manager.updateSchedule(taskID: task.id, timing: .part(.noon), weekdays: .all, targetMinutes: nil)
        let rows = try store.schedules(taskID: task.id)
        #expect(rows.count == 1)
        #expect(rows.first?.timing == .part(.noon))
        #expect(rows.first?.weekdays == Weekdays.none)
    }

    // MARK: Title, length, start day

    @Test func renameAppliesEverywhere() throws {
        let task = try habit()
        try manager.rename(taskID: task.id, to: " Gym ")
        #expect(try store.task(id: task.id)?.title == "Gym")
        #expect(throws: TaskError.invalid(.emptyTitle)) { try manager.rename(taskID: task.id, to: "") }
    }

    /// SPEC §4.1 (T-37): notes are trimmed, empty notes are stored as no value, and over 1,000 characters is refused.
    @Test func notesAreTrimmedClearedAndLimited() throws {
        let task = try habit()
        try manager.setNotes(taskID: task.id, notes: "  Before breakfast\n")
        #expect(try store.task(id: task.id)?.notes == "Before breakfast")
        try manager.setNotes(taskID: task.id, notes: " \n ")
        #expect(try store.task(id: task.id)?.notes == nil)
        #expect(throws: TaskError.invalid(.notesTooLong)) {
            try manager.setNotes(taskID: task.id, notes: String(repeating: "a", count: 1001))
        }
        #expect(try store.task(id: task.id)?.notes == nil)
    }

    /// Notes change wherever the title can: an ended habit's notes can, a past one-time task's can't.
    @Test func notesFollowTheTitlesEditingRules() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let ended = try habit()
        let past = try manager.createOneTime(title: "Call the bank", date: day(1), timing: .anytime)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.endHabit(taskID: ended.id)
        try manager.setNotes(taskID: ended.id, notes: "Paused for the holidays")
        #expect(try store.task(id: ended.id)?.notes == "Paused for the holidays")
        #expect(throws: TaskError.notAllowed) { try manager.setNotes(taskID: past.id, notes: "Too late") }
    }

    /// SPEC F-04 (T-38): Move to tomorrow on a missed task copies its notes too.
    @Test func moveToTomorrowCopiesTheNotes() throws {
        clock.now = TestEnvironment.date(2026, 10, 6, 7)
        let task = try manager.createOneTime(
            title: "Call the bank", notes: "Ask about the card", date: day(6), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        let copy = try manager.moveToNextDay(taskID: task.id)
        #expect(copy.id != task.id)
        #expect(copy.date == day(7))
        #expect(try store.task(id: copy.id)?.notes == "Ask about the card")
        #expect(try store.task(id: task.id)?.notes == "Ask about the card")
    }

    @Test func lengthMovesTheLastDay() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit(length: 30)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.setLength(taskID: task.id, lengthDays: 10)
        let updated = try #require(try store.task(id: task.id))
        #expect(updated.lengthDays == 10)
        #expect(updated.lastDay(in: calendar) == day(10))
        try manager.setLength(taskID: task.id, lengthDays: nil)
        #expect(try store.task(id: task.id)?.lastDay(in: calendar) == nil)
    }

    @Test func lengthEndingBeforeTodayEndsTheHabit() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit(length: 30)
        clock.now = TestEnvironment.date(2026, 10, 20, 9)
        try manager.setLength(taskID: task.id, lengthDays: 10)  // would end on 10 Oct
        let updated = try #require(try store.task(id: task.id))
        #expect(updated.endedOn == day(19))
        #expect(updated.lengthDays == 30)
        #expect(updated.lastDay(in: calendar) == day(19))
    }

    @Test func startDayMovesOnlyWhileInTheFuture() throws {
        let future = try habit(start: day(10))
        try manager.setStartDay(taskID: future.id, to: day(12))
        #expect(try store.task(id: future.id)?.startDay == day(12))
        #expect(try store.schedules(taskID: future.id).first?.effectiveFrom == day(12))
        #expect(throws: TaskError.invalid(.dayInPast)) { try manager.setStartDay(taskID: future.id, to: day(5)) }

        let started = try habit()
        #expect(throws: TaskError.notAllowed) { try manager.setStartDay(taskID: started.id, to: day(12)) }
    }

    // MARK: End, start again, delete

    @Test func endHabitMakesYesterdayTheLastDay() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit()
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.endHabit(taskID: task.id)
        let ended = try #require(try store.task(id: task.id))
        #expect(ended.endedOn == day(5))
        #expect(ended.hasEnded(today: day(6), calendar: calendar))
        #expect(try manager.engine().occurrence(of: ended, on: day(6)) == nil)
    }

    @Test func endHabitKeepsTodayWhenItHasACompletion() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit()
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try store.save(CompletionValue(taskID: task.id, day: day(6), createdAt: clock.now))
        try manager.endHabit(taskID: task.id)
        #expect(try store.task(id: task.id)?.endedOn == day(6))
    }

    @Test func endHabitKeepsTodayWhenItHasTime() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let task = try habit(type: .duration)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try store.save(
            TimeEntryValue(taskID: task.id, day: day(6), seconds: 300, source: .manual, createdAt: clock.now))
        try manager.endHabit(taskID: task.id)
        #expect(try store.task(id: task.id)?.endedOn == day(6))
    }

    @Test func startAgainCopiesTheHabitFromToday() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let old = try habit(type: .duration, weekdays: [.monday, .friday], length: 30, target: 45)
        try manager.updateSchedule(
            taskID: old.id, timing: .fixed(minute: 1080), weekdays: [.monday, .friday], targetMinutes: 45)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.endHabit(taskID: old.id)
        let new = try manager.startAgain(taskID: old.id)
        #expect(new.id != old.id)
        #expect(new.title == old.title)
        #expect(new.type == .duration)
        #expect(new.startDay == day(6))
        #expect(new.lengthDays == 30)
        #expect(new.endedOn == nil)
        let schedule = try #require(try store.schedules(taskID: new.id).first)
        #expect(schedule.timing == .fixed(minute: 1080))
        #expect(schedule.weekdays == [.monday, .friday])
        #expect(schedule.targetMinutes == 45)
        #expect(try store.task(id: old.id)?.endedOn == day(5))
    }

    @Test func deleteWithHistoryRemovesEveryRow() throws {
        let task = try habit(type: .duration)
        try store.save(
            TimeEntryValue(taskID: task.id, day: day(6), seconds: 300, source: .manual, createdAt: clock.now))
        let progress = try habit()
        try store.save(CompletionValue(taskID: progress.id, day: day(6), createdAt: clock.now))
        try manager.deleteWithHistory(taskID: task.id)
        try manager.deleteWithHistory(taskID: progress.id)
        let data = try store.loadAll()
        #expect(data.tasks.isEmpty)
        #expect(data.schedules.isEmpty)
        #expect(data.completions.isEmpty)
        #expect(data.timeEntries.isEmpty)
    }

    @Test func deleteOneTimeOnlyTakesOneTimeTasks() throws {
        let task = try manager.createOneTime(title: "Call", date: manager.today, timing: .anytime)
        let habit = try habit()
        #expect(throws: TaskError.wrongType) { try manager.deleteOneTime(taskID: habit.id) }
        try manager.deleteOneTime(taskID: task.id)
        #expect(try store.tasks().map(\.id) == [habit.id])
        #expect(throws: TaskError.notFound) { try manager.deleteOneTime(taskID: task.id) }
    }
}
