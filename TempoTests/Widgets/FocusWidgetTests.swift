import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-26: the Focus widget shows the next-task rule's result with its "when" and "Then:" lines.
@MainActor
struct FocusWidgetTests {
    private let clock = TestEnvironment.clock(hour: 9)
    private let store: SwiftDataTaskStore
    private let tasks: TaskManager

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        tasks = TaskManager(store: store, clock: clock, refresh: RefreshManager(widgets: WidgetReloadCounter()))
    }

    private func snapshot() throws -> WidgetSnapshot {
        try SnapshotLoader.load(store: store, deviceState: TestEnvironment.deviceState(), clock: clock)
    }

    private func content(at hour: Int, _ minute: Int = 0) throws -> FocusWidgetContent {
        FocusWidgetContent(snapshot: try snapshot(), at: TestEnvironment.date(2026, 10, 6, hour, minute))
    }

    @discardableResult
    private func make(_ title: String, _ timing: Timing) throws -> TaskValue {
        clock.advance(by: 1)
        return try tasks.createOneTime(title: title, date: tasks.today, timing: timing)
    }

    private func time(_ minute: Int) -> String { TimeOfDayFormatter.string(minute: minute) }

    @Test func fixedTimeWithinTheHourIsNext() throws {
        let interview = try make("Interview", .fixed(minute: 750))
        try make("Call the bank", .part(.noon))
        guard case .next(let item, let then) = try content(at: 11, 45) else {
            Issue.record("Expected a next item")
            return
        }
        #expect(item.taskID == interview.id)
        #expect(item.when == .next(minute: 750, date: TestEnvironment.date(2026, 10, 6, 12, 30)))
        #expect(item.when.label == "NEXT · \(time(750))")
        #expect(then?.title == "Call the bank")
        #expect(DeepLink(url: item.url) == .today(day: TestEnvironment.today, taskID: interview.id))
    }

    @Test func currentPartTaskThenTheFixedTask() throws {
        try make("Call the bank", .part(.noon))
        try make("Pick up", .fixed(minute: 960))
        guard case .next(let item, let then) = try content(at: 13) else {
            Issue.record("Expected a next item")
            return
        }
        #expect(item.title == "Call the bank")
        #expect(item.when.label == "NOON · until \(time(1020))")
        #expect(then?.title == "Pick up")
        #expect(then?.when.label == "NEXT · \(time(960))")
    }

    @Test func laterPartFromItsStart() throws {
        try make("Gym", .part(.evening))
        guard case .next(let item, let then) = try content(at: 13) else {
            Issue.record("Expected a next item")
            return
        }
        #expect(item.when.label == "EVENING · from \(time(1020))")
        #expect(then == nil)
    }

    @Test func anytimeAndDurationProgress() throws {
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: tasks.today, lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        guard case .next(let item, _) = try content(at: 22) else {
            Issue.record("Expected a next item")
            return
        }
        #expect(item.when.label == "ANYTIME")
        #expect(item.progress == "10 of 30 min")
    }

    @Test func freeWhenNothingIsLeft() throws {
        #expect(try content(at: 13) == .free(allDoneCount: nil))
        let call = try make("Call", .part(.noon))
        let gym = try make("Gym", .part(.evening))
        try tasks.complete(taskID: call.id, day: tasks.today)
        try tasks.complete(taskID: gym.id, day: tasks.today)
        let free = try content(at: 13)
        #expect(free == .free(allDoneCount: 2))
        #expect(DeepLink(url: free.url) == .today())
        // A missed task means not all were done (D-091).
        try make("Missed", .part(.morning))
        #expect(try content(at: 13) == .free(allDoneCount: nil))
    }

    @Test func changesOnItsOwnAsTimePasses() throws {
        try make("Interview", .fixed(minute: 750))
        try make("Gym", .part(.evening))
        // The widget's timeline has entries an hour before the fixed time and at each part start.
        let plan = WidgetTimelinePlan.make(now: TestEnvironment.date(2026, 10, 6, 9)) { try snapshot() }
        #expect(plan.moments.contains(TestEnvironment.date(2026, 10, 6, 11, 30)))
        guard case .next(let early, _) = try content(at: 11, 29), case .next(let soon, _) = try content(at: 11, 30)
        else {
            Issue.record("Expected next items")
            return
        }
        #expect(early.when.label == "NEXT · \(time(750))")  // rule 3: the earliest coming item
        #expect(soon.when == .next(minute: 750, date: TestEnvironment.date(2026, 10, 6, 12, 30)))
        guard case .next(let afternoon, _) = try content(at: 17) else {
            Issue.record("Expected a next item")
            return
        }
        #expect(afternoon.title == "Gym")
        #expect(afternoon.when.label == "EVENING · until \(time(1260))")
    }
}
