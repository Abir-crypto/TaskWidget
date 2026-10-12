import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-23, T-44: the Timer widget's states and its buttons.
@MainActor
struct TimerWidgetTests {
    private let clock = TestEnvironment.clock(hour: 10)
    private let store: SwiftDataTaskStore
    private let deviceState = TestEnvironment.deviceState()
    private let widgets = WidgetReloadCounter()
    private let environment: IntentEnvironment

    init() throws {
        store = try TestEnvironment.store(clock: clock)
        try store.save(SettingsValue.defaults)
        environment = IntentEnvironment.make(
            store: store, deviceState: deviceState, clock: clock, widgets: widgets,
            scheduler: FixedNotificationScheduler(permission: .allowed))
    }

    private var state: TimerWidgetState {
        let snapshot = try? SnapshotLoader.load(store: store, deviceState: deviceState, clock: clock)
        return TimerWidgetState(timer: snapshot?.timer, habitTitle: snapshot?.timerHabitTitle)
    }

    @Test func idleShowsStartAndOpensToday() {
        #expect(state == .idle)
        #expect(DeepLink(url: state.url) == .today())
    }

    @Test func startPauseResumeWithoutOpeningTheApp() async throws {
        try await StartGenericTimerIntent().run(in: environment)
        let started = clock.now
        #expect(state == .generic(.running(since: started)))
        #expect(DeepLink(url: state.url) == .timer)
        #expect(widgets.count >= 1)

        clock.advance(by: 312)
        try await PauseTimerIntent().run(in: environment)
        #expect(state == .generic(.paused(seconds: 312)))

        clock.advance(by: 600)
        try await ResumeTimerIntent().run(in: environment)
        // Counting continues from 312 seconds.
        #expect(state == .generic(.running(since: clock.now.addingTimeInterval(-312))))
    }

    @Test func doneFreezesTheTimeAndLeavesThePickerForTheApp() async throws {
        try await StartGenericTimerIntent().run(in: environment)
        clock.advance(by: 18 * 60)
        try await FinishGenericTimerIntent().run(in: environment)
        clock.advance(by: 120)  // opening the app and choosing doesn't add time
        #expect(deviceState.timer == nil)
        #expect(
            deviceState.pendingOpenAction
                == .chooseTaskForTimer(FinishedTimer(habitID: nil, day: TestEnvironment.today, seconds: 18 * 60)))
        #expect(state == .idle)
        #expect(FinishGenericTimerIntent.openAppWhenRun)
    }

    private func read() throws -> TaskValue {
        try environment.tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: environment.tasks.today,
            lengthDays: nil, targetMinutes: 30)
    }

    /// SPEC T-44: a habit timer started elsewhere has Pause/Resume here too (D-111).
    @Test func habitTimerCanBePausedAndResumedHere() async throws {
        let read = try read()
        try environment.timer.startHabitTimer(taskID: read.id)
        #expect(state == .habit(title: "Read", clock: .running(since: clock.now)))
        #expect(DeepLink(url: state.url) == .timer)
        // The generic Done does nothing to a habit timer.
        try await FinishGenericTimerIntent().run(in: environment)
        #expect(deviceState.timer?.habitID == read.id)
        #expect(deviceState.pendingOpenAction == nil)
        clock.advance(by: 90)
        try await PauseTimerIntent().run(in: environment)
        #expect(state == .habit(title: "Read", clock: .paused(seconds: 90)))
        try await ResumeTimerIntent().run(in: environment)
        #expect(state == .habit(title: "Read", clock: .running(since: clock.now.addingTimeInterval(-90))))
    }

    /// SPEC T-44: Done on a habit timer saves without opening the app; under a minute it saves nothing and goes back
    /// to Idle without a message.
    @Test func habitTimerDoneSavesWithoutOpeningTheApp() async throws {
        let read = try read()
        try environment.timer.startHabitTimer(taskID: read.id)
        clock.advance(by: 20 * 60)
        try await FinishHabitTimerIntent().run(in: environment)
        #expect(state == .idle)
        #expect(!FinishHabitTimerIntent.openAppWhenRun)
        #expect(deviceState.pendingOpenAction == nil)
        #expect(try store.timeEntries(taskID: read.id).map(\.seconds) == [20 * 60])

        try environment.timer.startHabitTimer(taskID: read.id)
        clock.advance(by: 40)
        try await FinishHabitTimerIntent().run(in: environment)
        #expect(state == .idle)
        #expect(try store.timeEntries(taskID: read.id).count == 1)
    }

    /// SPEC T-44: pausing anywhere shows as paused everywhere, because every place reads the one stored timer.
    @Test func pausingInOnePlaceShowsEverywhere() async throws {
        try await StartGenericTimerIntent().run(in: environment)
        clock.advance(by: 60)
        try await PauseTimerIntent().run(in: environment)
        let snapshot = try SnapshotLoader.load(store: store, deviceState: deviceState, clock: clock)
        #expect(state == .generic(.paused(seconds: 60)))
        try environment.tasks.createOneTime(title: "Call", date: environment.tasks.today, timing: .anytime)
        let now = try SnapshotLoader.load(store: store, deviceState: deviceState, clock: clock)
        guard case .list(let list) = NowWidgetContent(snapshot: now, at: clock.now) else {
            Issue.record("Expected list mode")
            return
        }
        #expect(list.genericTimer == .paused(seconds: 60))
        #expect(snapshot.timer.map(TimerRules.isRunning) == false)
    }

    @Test func startDoesNothingWhileATimerExists() async throws {
        try await StartGenericTimerIntent().run(in: environment)
        clock.advance(by: 60)
        try await StartGenericTimerIntent().run(in: environment)
        #expect(state == .generic(.running(since: clock.now.addingTimeInterval(-60))))
    }

    @Test func pausedClockText() {
        #expect(TimerClockValue.text(seconds: 312) == "5:12" || TimerClockValue.text(seconds: 312) == "05:12")
        #expect(TimerClockValue.text(seconds: 3_912).hasPrefix("1:05:12"))
    }
}
