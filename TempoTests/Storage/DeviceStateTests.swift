import Core
import Foundation
import Testing

@testable import Tempo

struct DeviceStateTests {
    private let suite = "tests.\(UUID().uuidString)"

    private func state() -> DeviceState {
        TestEnvironment.deviceState(suite: suite)
    }

    @Test func timerSurvivesARestart() {
        let timer = TimerState(
            kind: .habit, habitID: UUID(), startDay: TestEnvironment.today, accumulatedSeconds: 125,
            segmentStart: TestEnvironment.date(2026, 10, 6, 9, 30))
        state().timer = timer
        // A new instance on the same defaults stands in for a relaunched app or the widget extension.
        #expect(state().timer == timer)
    }

    @Test func pausedGenericTimerRoundTrips() {
        let timer = TimerState(
            kind: .generic, habitID: nil, startDay: TestEnvironment.today, accumulatedSeconds: 30, segmentStart: nil)
        state().timer = timer
        #expect(state().timer == timer)
        #expect(state().timer?.segmentStart == nil)
    }

    @Test func missedSeenListSurvivesARestart() {
        let seen = MissedSeenList(day: TestEnvironment.today, occurrenceIDs: ["a_20261006", "b_20261006"])
        state().missedSeen = seen
        #expect(state().missedSeen == seen)
    }

    @Test func pendingOpenActionSurvivesARestart() {
        let action = PendingOpenAction.chooseTaskForTimer(
            FinishedTimer(habitID: nil, day: TestEnvironment.today, seconds: 1_080))
        state().pendingOpenAction = action
        #expect(state().pendingOpenAction == action)
    }

    @Test func settingNilClears() {
        let state = state()
        state.timer = TimerState(kind: .generic, habitID: nil, startDay: TestEnvironment.today, segmentStart: nil)
        state.timer = nil
        #expect(state.timer == nil)
    }

    @Test func resetClearsEverything() {
        let state = state()
        state.timer = TimerState(kind: .generic, habitID: nil, startDay: TestEnvironment.today, segmentStart: nil)
        state.missedSeen = MissedSeenList(day: TestEnvironment.today)
        state.pendingOpenAction = .chooseTaskForTimer(
            FinishedTimer(habitID: nil, day: TestEnvironment.today, seconds: 60))
        state.reset()
        #expect(state.timer == nil)
        #expect(state.missedSeen == nil)
        #expect(state.pendingOpenAction == nil)
    }

    @Test func unreadableDataReadsAsEmpty() throws {
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(Data("not json".utf8), forKey: DeviceState.Key.timer.rawValue)
        #expect(state().timer == nil)
    }

    @Test func sharedStateUsesTheAppGroup() {
        #expect(UserDefaults(suiteName: StoreFactory.appGroup) != nil)
    }
}
