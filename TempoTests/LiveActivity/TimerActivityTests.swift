import AppIntents
import Core
import Foundation
import Testing

@testable import Tempo

/// SPEC T-45: what the timer's Live Activity shows, and that the timer intents run in the app's process.
@MainActor
struct TimerActivityTests {
    private let clock = TestEnvironment.clock(hour: 10)
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

    private func snapshot() throws -> Snapshot {
        Snapshot(data: try store.loadAll(), settings: try store.settings() ?? .defaults, calendar: clock.calendar)
    }

    private func read() throws -> TaskValue {
        try environment.tasks.createHabit(
            type: .duration, title: "Read", timing: .anytime, weekdays: .all, startDay: environment.tasks.today,
            lengthDays: nil, targetMinutes: 30)
    }

    @Test func aHabitTimerShowsItsNameClockAndTodaysProgress() throws {
        let read = try read()
        try environment.tasks.logTime(taskID: read.id, minutes: 10)
        try environment.timer.startHabitTimer(taskID: read.id)
        clock.advance(by: 312)
        let timer = try #require(deviceState.timer)
        let state = TimerActivityManager.contentState(for: timer, snapshot: try snapshot())
        #expect(state.habitTitle == "Read")
        #expect(state.runningSince == clock.now.addingTimeInterval(-312))
        #expect(state.earlierSeconds == 600)
        #expect(state.targetMinutes == 30)
        #expect(state.clock == .running(since: clock.now.addingTimeInterval(-312)))
        #expect(!state.hidesName)
        #expect(state.tint == "blue")
    }

    @Test func aPausedGenericTimerShowsTheTimeSoFar() throws {
        try environment.timer.startGenericTimer()
        clock.advance(by: 75)
        environment.timer.pause()
        let timer = try #require(deviceState.timer)
        let state = TimerActivityManager.contentState(for: timer, snapshot: try snapshot())
        #expect(state.habitTitle == nil)
        #expect(state.runningSince == nil)
        #expect(state.pausedSeconds == 75)
        #expect(state.targetMinutes == nil)
    }

    @Test func hideTaskNamesAndTheThemeColorCarryOver() throws {
        var settings = SettingsValue.defaults
        settings.hideLockScreenTitles = true
        settings.tintColor = .preset(.teal)
        try store.save(settings)
        try environment.timer.startGenericTimer()
        let timer = try #require(deviceState.timer)
        let state = TimerActivityManager.contentState(for: timer, snapshot: try snapshot())
        #expect(state.hidesName)
        #expect(state.tint == "teal")
    }

    /// The timer's buttons run in the app's process, which is the only place a Live Activity can be started, updated
    /// or ended (ios.md §8).
    @Test func timerIntentsAreLiveActivityIntents() {
        #expect((StartGenericTimerIntent() as Any) is any LiveActivityIntent)
        #expect((StartHabitTimerIntent() as Any) is any LiveActivityIntent)
        #expect((PauseTimerIntent() as Any) is any LiveActivityIntent)
        #expect((ResumeTimerIntent() as Any) is any LiveActivityIntent)
        #expect((FinishHabitTimerIntent() as Any) is any LiveActivityIntent)
        #expect((FinishGenericTimerIntent() as Any) is any LiveActivityIntent)
        #expect((DiscardTimerIntent() as Any) is any LiveActivityIntent)
    }

    /// Done from the Live Activity uses the same intent as the widgets: a timer that ran past midnight saves to the
    /// day it started (SPEC F-06, T-45).
    @Test func doneAfterMidnightSavesToTheDayTheTimerStarted() async throws {
        let read = try read()
        clock.now = TestEnvironment.date(2026, 10, 6, 23, 40)
        try environment.timer.startHabitTimer(taskID: read.id)
        clock.now = TestEnvironment.date(2026, 10, 7, 0, 20)
        try await FinishHabitTimerIntent().run(in: environment)
        #expect(try store.timeEntries(taskID: read.id).map(\.day) == [TestEnvironment.today])
        #expect(try store.timeEntries(taskID: read.id).map(\.seconds) == [40 * 60])
    }
}
