import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-24: the Now widget's list mode, its buttons, and timer mode.
@MainActor
struct NowWidgetTests {
    private let clock = TestEnvironment.clock(hour: 13)
    private let store: SwiftDataTaskStore
    private let deviceState = TestEnvironment.deviceState()
    private let environment: IntentEnvironment

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        environment = IntentEnvironment.make(
            store: store, deviceState: deviceState, clock: clock, widgets: WidgetReloadCounter(),
            scheduler: FixedNotificationScheduler(permission: .allowed))
    }

    private var tasks: TaskManager { environment.tasks }

    private func content(at date: Date? = nil) throws -> NowWidgetContent {
        let snapshot = try SnapshotLoader.load(store: store, deviceState: deviceState, clock: clock)
        return NowWidgetContent(snapshot: snapshot, at: date ?? clock.now)
    }

    private func list() throws -> NowList {
        guard case .list(let list) = try content() else { throw ContentError.notList }
        return list
    }

    private enum ContentError: Error { case notList, notTimer }

    @discardableResult
    private func make(_ title: String, _ timing: Timing) throws -> TaskValue {
        clock.advance(by: 1)
        return try tasks.createOneTime(title: title, date: tasks.today, timing: timing)
    }

    @Test func currentPartThenNextPartThenAnytime() throws {
        clock.now = TestEnvironment.date(2026, 10, 6, 9)
        try make("Morning", .part(.morning))
        try make("Noon", .part(.noon))
        try make("Evening", .part(.evening))
        try make("Anytime", .anytime)
        clock.now = TestEnvironment.date(2026, 10, 6, 13)
        let list = try list()
        // Morning has ended (missed), so the list starts with Noon, then Evening, then Anytime.
        #expect(list.groups.map(\.section.part) == [.noon, .evening, nil])
        #expect(list.groups.flatMap(\.items).map(\.task.title) == ["Noon", "Evening", "Anytime"])
        #expect(list.leftCount == 1)
        #expect(list.missedCount == 1)
        #expect(list.hiddenCount == 0)
        #expect(!list.isFree)
    }

    @Test func anEmptyCurrentPartLetsTheNextPartLead() throws {
        try make("Evening", .part(.evening))
        try make("Night", .part(.night))
        let list = try list()
        #expect(list.groups.map(\.section.part) == [.evening, .night])
    }

    @Test func tasksThatDontFitShowPlusMore() throws {
        for index in 0..<10 { try make("Noon \(index)", .part(.noon)) }
        try make("Evening", .part(.evening))
        let list = try list()
        #expect(list.groups.count == 1)
        #expect(list.groups.first?.items.count == NowWidgetContent.maximumRows)
        #expect(list.hiddenCount == 3)
    }

    @Test func freeAndEmptyStates() throws {
        #expect(try list().hasNoTasks)
        let call = try make("Call", .part(.noon))
        try tasks.complete(taskID: call.id, day: tasks.today)
        let list = try list()
        #expect(!list.hasNoTasks)
        #expect(list.isFree)
    }

    @Test func checkboxesCompleteAndUndoWithoutTheApp() async throws {
        let call = try make("Call", .part(.noon))
        let intent = ToggleCompletionIntent(taskID: call.id, day: tasks.today, done: true)
        intent.value = true
        try await intent.run(in: environment)
        #expect(try list().groups.first?.items.first?.status == .done)
        intent.value = false
        try await intent.run(in: environment)
        #expect(try list().groups.first?.items.first?.status == .open)
    }

    @Test func playTurnsTheWidgetIntoTheTimerAndDoneSaves() async throws {
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.noon), weekdays: .all, startDay: tasks.today,
            lengthDays: nil,
            targetMinutes: 30)
        try tasks.logTime(taskID: read.id, minutes: 10)
        #expect(try list().canStartTimers)

        try await StartHabitTimerIntent(taskID: read.id).run(in: environment)
        clock.advance(by: 12 * 60)
        guard case .timer(let timer) = try content() else { throw ContentError.notTimer }
        #expect(timer.title == "Read")
        #expect(timer.minutesToday == 22)
        #expect(timer.targetMinutes == 30)
        #expect(timer.progressInterval != nil)
        // The Timer widget shows the same timer, display only.
        let timerWidget = TimerWidgetState(timer: deviceState.timer, habitTitle: "Read")
        guard case .habit(let title, _) = timerWidget else { throw ContentError.notTimer }
        #expect(title == "Read")

        try await FinishHabitTimerIntent().run(in: environment)
        #expect(deviceState.timer == nil)
        #expect(try store.timeEntries(taskID: read.id).map(\.seconds).sorted() == [600, 720])
        #expect(try list().groups.first?.items.first?.minutes == 22)
    }

    @Test func discardSavesNothingAndReturnsToTheList() async throws {
        let read = try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.noon), weekdays: .all, startDay: tasks.today,
            lengthDays: nil,
            targetMinutes: 30)
        try await StartHabitTimerIntent(taskID: read.id).run(in: environment)
        clock.advance(by: 600)
        try await PauseTimerIntent().run(in: environment)
        guard case .timer(let paused) = try content() else { throw ContentError.notTimer }
        #expect(!paused.clock.isRunning)
        try await DiscardTimerIntent().run(in: environment)
        #expect(deviceState.timer == nil)
        #expect(try store.timeEntries(taskID: nil).isEmpty)
        _ = try list()
    }

    @Test func aGenericTimerShowsTheLineAndHidesEveryPlay() async throws {
        try tasks.createHabit(
            type: .duration, title: "Read", timing: .part(.noon), weekdays: .all, startDay: tasks.today,
            lengthDays: nil,
            targetMinutes: 30)
        try await StartGenericTimerIntent().run(in: environment)
        let list = try list()
        #expect(list.genericTimer == .running(since: clock.now))
        #expect(!list.canStartTimers)
    }
}
