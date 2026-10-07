import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct TaskPickerViewModelTests {
    private let clock = TestEnvironment.clock(hour: 13)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func duration(_ title: String, weekdays: Weekdays = .all, start: DayKey? = nil) throws -> TaskValue {
        clock.advance(by: 1)
        return try tasks.createHabit(
            type: .duration, title: title, timing: .anytime, weekdays: weekdays, startDay: start ?? tasks.today,
            lengthDays: nil, targetMinutes: 30)
    }

    private func request(movingEntry: UUID? = nil, habit: UUID? = nil) -> TaskPickerRequest {
        TaskPickerRequest(
            timer: FinishedTimer(habitID: habit, day: tasks.today, seconds: 1_080), movingEntryID: movingEntry)
    }

    @Test func habitsBelowTargetComeFirstThenTheRest() throws {
        let done = try duration("Done")
        try tasks.logTime(taskID: done.id, minutes: 30)
        let unscheduled = try duration("Monday only", weekdays: [.monday])
        let read = try duration("Read")
        try tasks.logTime(taskID: read.id, minutes: 10)
        let walk = try duration("Walk")
        _ = try duration("Later", start: DayKey(year: 2026, month: 10, day: 9))
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .anytime)

        let model = TaskPickerViewModel(tasks: tasks, request: request())
        model.load()
        #expect(model.habits.map(\.task.id) == [read.id, walk.id, done.id, unscheduled.id])
        #expect(model.habits.first?.progress == "10 of 30 min")
        #expect(model.habits.first?.needsTime == true)
        #expect(model.habits.last?.progress == "0 min")
        #expect(model.timeText == "18 min")
    }

    @Test func emptyWithoutDurationHabits() throws {
        try tasks.createOneTime(title: "Call", date: tasks.today, timing: .anytime)
        let model = TaskPickerViewModel(tasks: tasks, request: request())
        model.load()
        #expect(model.isLoaded)
        #expect(model.habits.isEmpty)
    }

    @Test func movingLeavesOutTheCurrentHabit() throws {
        let read = try duration("Read")
        let walk = try duration("Walk")
        let model = TaskPickerViewModel(tasks: tasks, request: request(movingEntry: UUID(), habit: read.id))
        model.load()
        #expect(model.isMoving)
        #expect(model.habits.map(\.task.id) == [walk.id])
    }
}
