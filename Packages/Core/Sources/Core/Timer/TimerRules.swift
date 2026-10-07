import Foundation

/// The timer's state machine (SPEC F-06): start, pause, resume, finish, discard and the running alert.
///
/// Time is measured from stored moments, so a timer survives the app being closed or the device restarting.
/// If the device clock is moved back, the time counted never goes below zero.
public enum TimerRules {
    /// Under one minute, nothing is saved (SPEC F-06).
    public static let minimumSeconds = 60

    /// A new running timer. Its time will be saved to the day it starts.
    public static func start(kind: TimerKind, habitID: UUID?, now: Date, calendar: Calendar) -> TimerState {
        TimerState(
            kind: kind, habitID: kind == .habit ? habitID : nil, startDay: DayKey(now, calendar: calendar),
            accumulatedSeconds: 0, segmentStart: now)
    }

    public static func isRunning(_ state: TimerState) -> Bool {
        state.segmentStart != nil
    }

    /// Seconds counted so far: earlier segments plus the current one. Paused time isn't counted.
    public static func elapsed(_ state: TimerState, now: Date) -> TimeInterval {
        let current = state.segmentStart.map { max(now.timeIntervalSince($0), 0) } ?? 0
        return max(state.accumulatedSeconds + current, 0)
    }

    /// Stops counting. Pausing a paused timer changes nothing.
    public static func pause(_ state: TimerState, now: Date) -> TimerState {
        guard isRunning(state) else { return state }
        var paused = state
        paused.accumulatedSeconds = elapsed(state, now: now)
        paused.segmentStart = nil
        return paused
    }

    /// Starts counting again from now. Resuming a running timer changes nothing.
    public static func resume(_ state: TimerState, now: Date) -> TimerState {
        guard !isRunning(state) else { return state }
        var resumed = state
        resumed.segmentStart = now
        return resumed
    }

    /// Done: the clock stops at `now`, the moment Done was tapped. The time belongs to the day it started.
    public static func finish(_ state: TimerState, now: Date) -> FinishedTimer {
        FinishedTimer(habitID: state.habitID, day: state.startDay, seconds: Int(elapsed(state, now: now)))
    }

    /// Whether a finished timer has enough time to save.
    public static func shouldSave(_ finished: FinishedTimer) -> Bool {
        finished.seconds >= minimumSeconds
    }

    /// When the running alert next fires: a whole number of alert periods after the timer was last started or
    /// resumed, the first one after now (SPEC F-06). "Keep going" lets it come back one period later. `nil`
    /// while paused.
    public static func nextAlert(_ state: TimerState, periodMinutes: Int, now: Date) -> Date? {
        guard let segmentStart = state.segmentStart, periodMinutes > 0 else { return nil }
        let period = TimeInterval(periodMinutes * 60)
        let periods = max(floor(now.timeIntervalSince(segmentStart) / period) + 1, 1)
        return segmentStart.addingTimeInterval(periods * period)
    }
}
