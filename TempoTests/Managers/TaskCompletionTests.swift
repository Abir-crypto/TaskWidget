import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC F-04 through `TaskManager`: completing, undoing, moving, and what each day allows.
@MainActor
struct TaskCompletionTests {
    private let clock = TestEnvironment.clock(hour: 10)
    private let store: SwiftDataTaskStore
    private let manager: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        manager = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func day(_ day: Int) -> DayKey { DayKey(year: 2026, month: 10, day: day) }

    private func status(_ task: TaskValue, on day: DayKey) throws -> Status? {
        let snapshot = try manager.snapshot()
        return snapshot.engine.occurrence(of: task, on: day).map { snapshot.status(of: $0, now: clock.now) }
    }

    @Test func completeAndUndoToday() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .part(.noon))
        try manager.complete(taskID: task.id, day: day(6))
        try manager.complete(taskID: task.id, day: day(6))  // twice: still one row
        #expect(try store.completions(taskID: task.id).count == 1)
        #expect(try status(task, on: day(6)) == .done)
        try manager.undoCompletion(taskID: task.id, day: day(6))
        #expect(try store.completions(taskID: task.id).isEmpty)
        #expect(try status(task, on: day(6)) == .upcoming)
    }

    @Test func noonTaskCompletedAfterItsPartIsDone() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .part(.noon))
        clock.now = TestEnvironment.date(2026, 10, 6, 17, 0)
        #expect(try status(task, on: day(6)) == .missed)
        clock.now = TestEnvironment.date(2026, 10, 6, 18, 0)
        try manager.complete(taskID: task.id, day: day(6))
        #expect(try status(task, on: day(6)) == .done)
    }

    @Test func undoRemovesDuplicateRows() throws {
        let habit = try manager.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        // A future sync could produce duplicates (SPEC §4.3).
        try store.save(CompletionValue(taskID: habit.id, day: day(6), createdAt: clock.now))
        try store.save(CompletionValue(taskID: habit.id, day: day(6), createdAt: clock.now))
        try manager.undoCompletion(taskID: habit.id, day: day(6))
        #expect(try store.completions(taskID: habit.id).isEmpty)
    }

    @Test func toggleFlipsTheState() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .anytime)
        try manager.toggleCompletion(taskID: task.id, day: day(6))
        #expect(try status(task, on: day(6)) == .done)
        try manager.toggleCompletion(taskID: task.id, day: day(6))
        #expect(try status(task, on: day(6)) == .open)
    }

    @Test func pastDaysAreReadOnly() throws {
        clock.now = TestEnvironment.date(2026, 10, 5, 9)
        let task = try manager.createOneTime(title: "Yesterday", date: day(5), timing: .anytime)
        let habit = try manager.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(5), lengthDays: nil,
            targetMinutes: nil)
        clock.now = TestEnvironment.date(2026, 10, 6, 13)  // after the correction window (SPEC §5.11)
        #expect(throws: TaskError.notAllowed) { try manager.complete(taskID: task.id, day: day(5)) }
        #expect(throws: TaskError.notAllowed) { try manager.complete(taskID: habit.id, day: day(5)) }
        #expect(throws: TaskError.notAllowed) { try manager.moveToNextDay(taskID: task.id) }
        #expect(throws: TaskError.notAllowed) { try manager.rename(taskID: task.id, to: "New") }
        #expect(throws: TaskError.notAllowed) {
            try manager.updateSchedule(taskID: task.id, timing: .part(.noon), weekdays: .none, targetMinutes: nil)
        }
        #expect(throws: TaskError.notAllowed) { try manager.deleteOneTime(taskID: task.id) }
        #expect(try store.completions(taskID: nil).isEmpty)
    }

    @Test func futureOneTimeTaskCanBeCompletedEarly() throws {
        let task = try manager.createOneTime(title: "Thursday", date: day(8), timing: .anytime)
        try manager.complete(taskID: task.id, day: day(8))
        #expect(try store.completions(taskID: task.id).map(\.day) == [day(8)])
        #expect(try status(task, on: day(8)) == .done)
    }

    @Test func futureHabitOccurrenceCantBeCompleted() throws {
        let habit = try manager.createHabit(
            type: .progress, title: "Medicine", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        #expect(throws: TaskError.notAllowed) { try manager.complete(taskID: habit.id, day: day(7)) }
    }

    @Test func durationHabitsAreNotCheckedOff() throws {
        let habit = try manager.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: day(6), lengthDays: nil,
            targetMinutes: 30)
        #expect(throws: TaskError.wrongType) { try manager.complete(taskID: habit.id, day: day(6)) }
    }

    @Test func unscheduledDayCantBeCompleted() throws {
        let habit = try manager.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: [.monday], startDay: day(6), lengthDays: nil,
            targetMinutes: nil)
        #expect(throws: TaskError.notAllowed) { try manager.complete(taskID: habit.id, day: day(6)) }
    }

    // MARK: Move to tomorrow

    @Test func taskThatIsNotMissedMovesItsDate() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .part(.evening))
        let moved = try manager.moveToNextDay(taskID: task.id)
        #expect(moved.id == task.id)
        #expect(try store.task(id: task.id)?.date == day(7))
        #expect(try store.tasks().count == 1)
        #expect(try manager.engine().occurrences(on: day(6)).isEmpty)
    }

    @Test func missedTaskStaysMissedAndGetsACopy() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .part(.morning))
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        #expect(try status(task, on: day(6)) == .missed)
        let copy = try manager.moveToNextDay(taskID: task.id)
        #expect(copy.id != task.id)
        #expect(copy.title == "Call")
        #expect(copy.date == day(7))
        #expect(try store.schedules(taskID: copy.id).first?.timing == .part(.morning))
        #expect(try store.task(id: task.id)?.date == day(6))
        #expect(try status(task, on: day(6)) == .missed)
        #expect(try status(copy, on: day(7)) == .upcoming)
    }

    @Test func futureTaskMovesToTheNextDay() throws {
        let task = try manager.createOneTime(title: "Thursday", date: day(8), timing: .anytime)
        try manager.moveToNextDay(taskID: task.id)
        #expect(try store.task(id: task.id)?.date == day(9))
    }

    @Test func doneTaskDoesNotMove() throws {
        let task = try manager.createOneTime(title: "Call", date: day(6), timing: .anytime)
        try manager.complete(taskID: task.id, day: day(6))
        #expect(throws: TaskError.notAllowed) { try manager.moveToNextDay(taskID: task.id) }
    }

    @Test func endedHabitScheduleIsFrozen() throws {
        clock.now = TestEnvironment.date(2026, 10, 1, 9)
        let habit = try manager.createHabit(
            type: .progress, title: "Gym", timing: .anytime, weekdays: .all, startDay: day(1), lengthDays: nil,
            targetMinutes: nil)
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try manager.endHabit(taskID: habit.id)
        #expect(throws: TaskError.notAllowed) {
            try manager.updateSchedule(taskID: habit.id, timing: .part(.noon), weekdays: .all, targetMinutes: nil)
        }
        #expect(throws: TaskError.notAllowed) { try manager.setLength(taskID: habit.id, lengthDays: 30) }
        try manager.rename(taskID: habit.id, to: "Gym sessions")  // titles still change everywhere
        #expect(try store.task(id: habit.id)?.title == "Gym sessions")
    }
}
