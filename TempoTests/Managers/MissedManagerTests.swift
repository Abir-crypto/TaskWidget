import Core
import Foundation
import Testing

@testable import Tempo

@MainActor
struct MissedManagerTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager
    private let missed: MissedManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
        missed = MissedManager(tasks: tasks, deviceState: TestEnvironment.deviceState(), clock: clock)
    }

    @Test func badgeCountsTodaysMissedAndShort() throws {
        try tasks.createOneTime(title: "Morning", date: tasks.today, timing: .part(.morning))
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.morning), weekdays: .all, startDay: tasks.today,
            lengthDays: nil, targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        try tasks.createOneTime(title: "Evening", date: tasks.today, timing: .part(.evening))
        #expect(missed.missedTodayCount() == 0)
        clock.now = TestEnvironment.date(2026, 10, 6, 12, 0)
        #expect(missed.missedTodayCount() == 2)
    }
}
