import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct LogTimeViewModelTests {
    private let clock = TestEnvironment.clock(hour: 18)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func read(start: DayKey = TestEnvironment.today) throws -> TaskValue {
        try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: start, lengthDays: nil,
            targetMinutes: 30)
    }

    @Test func startsAtTheMinutesLeftAndAddsToToday() throws {
        let task = try read()
        try tasks.logTime(taskID: task.id, minutes: 10)
        try store.save(
            TimeEntryValue(
                taskID: task.id, day: TestEnvironment.today, seconds: 120, source: .timer, createdAt: clock.now))
        let model = LogTimeViewModel(tasks: tasks, taskID: task.id)
        model.load()
        #expect(model.title == "Read")
        #expect(model.minutesToday == 12)
        #expect(model.targetMinutes == 30)
        #expect(model.minutes == 20)  // 18 left, rounded up to 20
        #expect(model.canLog)
        #expect(model.save())
        #expect(try tasks.snapshot().activity.minutes(taskID: task.id, day: TestEnvironment.today) == 32)
    }

    @Test func startsAt30OnceTheTargetIsReached() throws {
        let task = try read()
        try tasks.logTime(taskID: task.id, minutes: 30)
        let model = LogTimeViewModel(tasks: tasks, taskID: task.id)
        model.load()
        #expect(model.minutes == 30)
    }

    @Test func offersFiveTo480InFives() throws {
        let model = LogTimeViewModel(tasks: tasks, taskID: try read().id)
        #expect(model.choices.first == 5)
        #expect(model.choices.last == 480)
        #expect(model.choices.count == 96)
    }

    @Test func refusedOutsideTheHabitsDays() throws {
        let task = try read(start: DayKey(year: 2026, month: 10, day: 8))
        let model = LogTimeViewModel(tasks: tasks, taskID: task.id)
        model.load()
        #expect(!model.canLog)
        #expect(!model.save())
        #expect(model.errorMessage != nil)
    }
}
