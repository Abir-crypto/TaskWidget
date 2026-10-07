import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-19 through `TimerManager`.
@MainActor
struct TimerManagerTests {
    private let clock = TestEnvironment.clock(hour: 10)
    private let store: SwiftDataTaskStore
    private let deviceState = TestEnvironment.deviceState()
    private let tasks: TaskManager
    private let timer: TimerManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        let refresh = RefreshManager(widgets: WidgetReloadCounter())
        tasks = TaskManager(store: store, clock: clock, refresh: refresh, deviceState: deviceState)
        timer = TimerManager(deviceState: deviceState, tasks: tasks, clock: clock, refresh: refresh)
    }

    private func read(start: DayKey = TestEnvironment.today) throws -> TaskValue {
        try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: .all, startDay: start, lengthDays: nil,
            targetMinutes: 30)
    }

    @Test func onlyOneTimerCanExist() throws {
        let habit = try read()
        try timer.startHabitTimer(taskID: habit.id)
        #expect(throws: TimerError.timerExists) { try timer.startGenericTimer() }
        #expect(throws: TimerError.timerExists) { try timer.startHabitTimer(taskID: habit.id) }
        timer.pause()
        #expect(throws: TimerError.timerExists) { try timer.startGenericTimer() }
        timer.discard()
        try timer.startGenericTimer()
        #expect(timer.state?.kind == .generic)
    }

    @Test func onlyHabitsLiveTodayCanBeTimed() throws {
        let later = try read(start: DayKey(year: 2026, month: 10, day: 9))
        #expect(throws: TimerError.cantTimeHabit) { try timer.startHabitTimer(taskID: later.id) }
        let oneTime = try tasks.createOneTime(title: "Call", date: tasks.today, timing: .anytime)
        #expect(throws: TimerError.cantTimeHabit) { try timer.startHabitTimer(taskID: oneTime.id) }
        #expect(timer.state == nil)
    }

    @Test func pausedTimeIsNotCountedAndPauseResumeRepeat() throws {
        try timer.startGenericTimer()
        clock.advance(by: 300)
        timer.pause()
        clock.advance(by: 3_600)
        #expect(timer.elapsed() == 300)
        #expect(!timer.isRunning)
        for _ in 0..<3 {
            timer.resume()
            clock.advance(by: 60)
            timer.pause()
            clock.advance(by: 600)
        }
        #expect(timer.elapsed() == 480)
    }

    @Test func timeFreezesAtDone() throws {
        let habit = try read()
        try timer.startHabitTimer(taskID: habit.id)
        clock.advance(by: 18 * 60)
        let result = try timer.finishHabitTimer()
        clock.advance(by: 600)
        guard case .saved(let entry) = result else {
            Issue.record("Expected a saved entry")
            return
        }
        #expect(entry.seconds == 18 * 60)
        #expect(entry.source == .timer)
        #expect(timer.state == nil)
        #expect(try store.timeEntries(taskID: habit.id).map(\.seconds) == [18 * 60])
    }

    @Test func underOneMinuteNothingIsSaved() throws {
        let habit = try read()
        try timer.startHabitTimer(taskID: habit.id)
        clock.advance(by: 59)
        #expect(try timer.finishHabitTimer() == .tooShort)
        #expect(try store.timeEntries(taskID: nil).isEmpty)
        #expect(timer.state == nil)
    }

    @Test func timeAfterMidnightIsSavedToTheDayItStarted() throws {
        let habit = try read()
        clock.now = TestEnvironment.date(2026, 10, 6, 23, 40)
        try timer.startHabitTimer(taskID: habit.id)
        clock.now = TestEnvironment.date(2026, 10, 7, 0, 20)
        let result = try timer.finishHabitTimer()
        guard case .saved(let entry) = result else {
            Issue.record("Expected a saved entry")
            return
        }
        #expect(entry.day == TestEnvironment.today)
        #expect(entry.seconds == 40 * 60)
    }

    @Test func discardSavesNothing() throws {
        let habit = try read()
        try timer.startHabitTimer(taskID: habit.id)
        clock.advance(by: 1_200)
        timer.discard()
        #expect(timer.state == nil)
        #expect(try store.timeEntries(taskID: nil).isEmpty)
    }

    @Test func genericTimerTimeGoesToTheChosenHabit() throws {
        let habit = try read()
        try timer.startGenericTimer()
        clock.advance(by: 25 * 60)
        let finished = try timer.finish()
        #expect(finished.habitID == nil)
        clock.advance(by: 120)  // choosing a habit doesn't add time
        guard case .saved(let entry) = try timer.save(finished, to: habit.id) else {
            Issue.record("Expected a saved entry")
            return
        }
        #expect(entry.seconds == 25 * 60)
        #expect(entry.taskID == habit.id)
    }

    @Test func alertFollowsTheLastStartOrResumeAndPausingCancelsIt() throws {
        try timer.startGenericTimer()
        let started = clock.now
        #expect(timer.nextAlert(periodMinutes: 120) == started.addingTimeInterval(7_200))
        clock.advance(by: 1_800)
        timer.pause()
        #expect(timer.nextAlert(periodMinutes: 120) == nil)
        clock.advance(by: 600)
        timer.resume()
        #expect(timer.nextAlert(periodMinutes: 120) == clock.now.addingTimeInterval(7_200))
    }

    @Test func endingOrDeletingTheTimedHabitDiscardsTheTimer() throws {
        let first = try read()
        try timer.startHabitTimer(taskID: first.id)
        try tasks.endHabit(taskID: first.id)
        #expect(timer.state == nil)

        let second = try read()
        try timer.startHabitTimer(taskID: second.id)
        try tasks.deleteWithHistory(taskID: second.id)
        #expect(timer.state == nil)
    }

    @Test func endingAnotherHabitKeepsTheTimer() throws {
        let timed = try read()
        let other = try read()
        try timer.startHabitTimer(taskID: timed.id)
        try tasks.endHabit(taskID: other.id)
        #expect(timer.state?.habitID == timed.id)
    }

    @Test func timerSurvivesARestart() throws {
        let habit = try read()
        try timer.startHabitTimer(taskID: habit.id)
        clock.advance(by: 90)
        let relaunched = TimerManager(
            deviceState: deviceState, tasks: tasks, clock: clock,
            refresh: RefreshManager(widgets: WidgetReloadCounter()))
        #expect(relaunched.state?.habitID == habit.id)
        #expect(relaunched.elapsed() == 90)
    }

    @Test func changeTaskAndUndoForTheConfirmation() throws {
        let read = try read()
        let walk = try tasks.createHabit(
            type: .duration, title: "Walk", timing: .anytime, weekdays: .all, startDay: tasks.today, lengthDays: nil,
            targetMinutes: 20)
        try timer.startHabitTimer(taskID: read.id)
        clock.advance(by: 600)
        guard case .saved(let entry) = try timer.finishHabitTimer() else {
            Issue.record("Expected a saved entry")
            return
        }
        try tasks.moveTimeEntry(id: entry.id, to: walk.id)
        #expect(try store.timeEntries(taskID: walk.id).map(\.id) == [entry.id])
        try tasks.undoTimerEntry(id: entry.id)
        #expect(try store.timeEntries(taskID: nil).isEmpty)
    }
}
