import Core
import Foundation

/// The one timer on the device (SPEC F-06), stored in `DeviceState` so the app and the widgets share it.
@MainActor
final class TimerManager {
    private let deviceState: DeviceState
    private let tasks: TaskManager
    private let clock: any Clock
    private let refresh: RefreshManager

    init(deviceState: DeviceState, tasks: TaskManager, clock: any Clock, refresh: RefreshManager) {
        self.deviceState = deviceState
        self.tasks = tasks
        self.clock = clock
        self.refresh = refresh
    }

    /// The timer, or `nil` when idle.
    var state: TimerState? { deviceState.timer }

    var isRunning: Bool { state.map(TimerRules.isRunning) ?? false }

    func elapsed(at now: Date? = nil) -> TimeInterval {
        state.map { TimerRules.elapsed($0, now: now ?? clock.now) } ?? 0
    }

    // MARK: Start

    /// ▶ on a duration habit: starts counting straight away. Only one timer can exist.
    func startHabitTimer(taskID: UUID) throws {
        guard state == nil else { throw TimerError.timerExists }
        guard let task = try tasks.engine().task(id: taskID),
            // A timer counts for today; the correction window is for logging by hand (SPEC F-06, §5.11).
            Editability.canLogTime(
                task: task, day: tasks.today, in: EditWindow(today: tasks.today), calendar: clock.calendar)
        else { throw TimerError.cantTimeHabit }
        save(TimerRules.start(kind: .habit, habitID: taskID, now: clock.now, calendar: clock.calendar))
    }

    /// Start in the Timer widget: a timer with no habit; the habit is chosen at Done.
    func startGenericTimer() throws {
        guard state == nil else { throw TimerError.timerExists }
        save(TimerRules.start(kind: .generic, habitID: nil, now: clock.now, calendar: clock.calendar))
    }

    // MARK: Pause and resume

    func pause() {
        guard let state else { return }
        save(TimerRules.pause(state, now: clock.now))
    }

    func resume() {
        guard let state else { return }
        save(TimerRules.resume(state, now: clock.now))
    }

    // MARK: Done and Discard

    /// Done: stops the clock at this moment and clears the timer. Returns the frozen time.
    @discardableResult
    func finish() throws -> FinishedTimer {
        guard let state else { throw TimerError.noTimer }
        let finished = TimerRules.finish(state, now: clock.now)
        save(nil)
        return finished
    }

    /// Done on a habit timer: freezes the time and saves it to the habit, on the day the timer started.
    /// Under a minute, nothing is saved.
    func finishHabitTimer() throws -> TimerSaveResult {
        guard let habitID = state?.habitID else { throw TimerError.noTimer }
        return try save(try finish(), to: habitID)
    }

    /// Saves a finished timer's time to a habit, for example the one picked for a generic timer.
    func save(_ finished: FinishedTimer, to taskID: UUID) throws -> TimerSaveResult {
        guard TimerRules.shouldSave(finished) else { return .tooShort }
        return .saved(try tasks.addTimerEntry(taskID: taskID, finished: finished))
    }

    /// Discard: stops the timer and saves nothing.
    func discard() {
        guard state != nil else { return }
        save(nil)
    }

    /// When the running-timer alert should next fire, or `nil` (SPEC F-06, F-07).
    func nextAlert(periodMinutes: Int) -> Date? {
        state.flatMap { TimerRules.nextAlert($0, periodMinutes: periodMinutes, now: clock.now) }
    }

    private func save(_ state: TimerState?) {
        deviceState.timer = state
        refresh.afterChange()
    }
}
