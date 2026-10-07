import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TimerControllerTests {
    private let clock = TestEnvironment.clock(hour: 18)
    private let dependencies: AppDependencies
    private let router = NavigationRouter()
    private let controller: TimerController

    init() throws {
        dependencies = AppDependencies(
            clock: clock, store: try TestEnvironment.store(clock: clock), deviceState: TestEnvironment.deviceState(),
            notifications: FixedNotificationScheduler(permission: .allowed), widgets: WidgetReloadCounter())
        dependencies.prepare()
        controller = TimerController(dependencies: dependencies, router: router)
    }

    private func read() throws -> TaskValue {
        try dependencies.tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.evening), weekdays: .all,
            startDay: dependencies.tasks.today, lengthDays: nil, targetMinutes: 30)
    }

    @Test func playStartsAHabitTimerAndTheBarShowsIt() throws {
        let habit = try read()
        try dependencies.tasks.logTime(taskID: habit.id, minutes: 10)
        controller.startHabit(habit.id)
        let active = try #require(controller.active)
        #expect(active.title == "Read")
        #expect(active.isRunning)
        #expect(active.minutesBefore == 10)
        #expect(active.targetMinutes == 30)
        #expect(controller.isTiming(habit.id))
        controller.pause()
        #expect(controller.active?.isRunning == false)
        controller.resume()
        #expect(controller.active?.isRunning == true)
    }

    @Test func doneSavesAndConfirms() throws {
        let habit = try read()
        try dependencies.tasks.logTime(taskID: habit.id, minutes: 10)
        router.isTimerScreenPresented = true
        controller.startHabit(habit.id)
        clock.advance(by: 18 * 60)
        controller.done()
        #expect(controller.active == nil)
        #expect(!router.isTimerScreenPresented)
        let toast = try #require(controller.toast)
        #expect(toast.message == "Added 18 min to Read · 28 of 30 min today")
        #expect(toast.entry?.seconds == 18 * 60)
    }

    @Test func underAMinuteSavesNothing() throws {
        let habit = try read()
        controller.startHabit(habit.id)
        clock.advance(by: 30)
        controller.done()
        #expect(controller.toast?.message == "Less than a minute, nothing saved.")
        #expect(controller.toast?.entry == nil)
        #expect(try dependencies.store.timeEntries(taskID: nil).isEmpty)
    }

    @Test func genericDoneOpensThePickerAndChoosingSaves() throws {
        let habit = try read()
        try dependencies.timer.startGenericTimer()
        controller.load()
        #expect(controller.active?.title == "Timer")
        clock.advance(by: 20 * 60)
        controller.done()
        let request = try #require(router.taskPicker)
        #expect(request.timer.seconds == 20 * 60)
        #expect(dependencies.timer.state == nil)
        clock.advance(by: 60)  // choosing doesn't add time
        controller.choose(habit.id, for: request)
        #expect(router.taskPicker == nil)
        #expect(controller.toast?.message == "Added 20 min to Read · 20 of 30 min today")
    }

    @Test func undoDeletesTheEntry() throws {
        let habit = try read()
        controller.startHabit(habit.id)
        clock.advance(by: 600)
        controller.done()
        controller.undo(try #require(controller.toast))
        #expect(controller.toast == nil)
        #expect(try dependencies.store.timeEntries(taskID: nil).isEmpty)
    }

    @Test func changeTaskMovesTheEntry() throws {
        let habit = try read()
        let walk = try dependencies.tasks.createHabit(
            type: .duration, title: "Walk", timing: .anytime, weekdays: .all, startDay: dependencies.tasks.today,
            lengthDays: nil, targetMinutes: 20)
        controller.startHabit(habit.id)
        clock.advance(by: 600)
        controller.done()
        let toast = try #require(controller.toast)
        controller.changeTask(toast)
        let request = try #require(router.taskPicker)
        #expect(request.movingEntryID == toast.entry?.id)
        controller.choose(walk.id, for: request)
        #expect(try dependencies.store.timeEntries(taskID: walk.id).count == 1)
        #expect(try dependencies.store.timeEntries(taskID: habit.id).isEmpty)
        #expect(controller.toast?.message == "Added 10 min to Walk · 10 of 20 min today")
    }

    @Test func discardSavesNothing() throws {
        let habit = try read()
        controller.startHabit(habit.id)
        clock.advance(by: 600)
        controller.discard()
        #expect(controller.active == nil)
        #expect(try dependencies.store.timeEntries(taskID: nil).isEmpty)
    }

    @Test func thePickerComesBackAfterAddingADurationTask() {
        let request = TaskPickerRequest(timer: FinishedTimer(habitID: nil, day: TestEnvironment.today, seconds: 600))
        router.resumePickerAfterEditor = request
        router.editorDidClose()
        #expect(router.taskPicker == request)
        #expect(router.resumePickerAfterEditor == nil)
    }
}
