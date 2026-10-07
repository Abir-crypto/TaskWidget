import Core
import Foundation
import Observation

/// Runs the timer from the app's screens (SPEC F-06): starting from ▶, the timer bar and screen's controls,
/// Done (saving with a confirmation, or opening the task picker), Discard, and the confirmation's Undo and
/// Change task.
@Observable
@MainActor
final class TimerController {
    /// The timer, reloaded from storage after every change.
    private(set) var active: ActiveTimer?
    /// The confirmation on screen, if any.
    var toast: TimerToast?

    private let dependencies: AppDependencies
    private let router: NavigationRouter
    private var hideToast: Task<Void, Never>?

    init(dependencies: AppDependencies, router: NavigationRouter) {
        self.dependencies = dependencies
        self.router = router
    }

    /// "Now" from the app's clock.
    var now: Date { dependencies.clock.now }

    private var timer: TimerManager { dependencies.timer }
    private var tasks: TaskManager { dependencies.tasks }

    /// How long the confirmation stays (SPEC F-06: about 5 seconds).
    static let toastDuration: Duration = .seconds(5)

    func load() {
        guard let state = timer.state else {
            active = nil
            return
        }
        do {
            let snapshot = try tasks.snapshot()
            let today = tasks.today
            let habit = state.habitID.flatMap { snapshot.engine.task(id: $0) }
            active = ActiveTimer(
                state: state,
                title: habit?.title ?? String(localized: "Timer"),
                minutesBefore: habit.map { snapshot.activity.minutes(taskID: $0.id, day: today) } ?? 0,
                targetMinutes: habit.flatMap { snapshot.engine.schedule(for: $0.id, on: today)?.targetMinutes })
        } catch {
            Log.tasks.error("Couldn't load the timer: \(error)")
        }
    }

    /// Whether a habit's timer exists, so ending or deleting it can warn first (SPEC F-10).
    func isTiming(_ taskID: UUID) -> Bool {
        timer.state?.habitID == taskID
    }

    // MARK: Controls

    /// ▶ on a duration habit.
    func startHabit(_ taskID: UUID) {
        do {
            try timer.startHabitTimer(taskID: taskID)
        } catch {
            Log.tasks.error("Couldn't start the timer: \(error)")
        }
        load()
    }

    func pause() {
        timer.pause()
        load()
    }

    func resume() {
        timer.resume()
        load()
    }

    /// Done: a habit timer saves its time and confirms; a generic timer opens the task picker. The clock stops
    /// at this moment either way.
    func done() {
        guard let state = timer.state else { return }
        do {
            if state.kind == .habit {
                show(try timer.finishHabitTimer())
            } else {
                router.taskPicker = TaskPickerRequest(timer: try timer.finish())
            }
        } catch {
            Log.tasks.error("Couldn't finish the timer: \(error)")
        }
        router.isTimerScreenPresented = false
        load()
    }

    /// Discard: stops the timer and saves nothing.
    func discard() {
        timer.discard()
        router.isTimerScreenPresented = false
        load()
    }

    // MARK: Task picker

    /// Saves the picked habit: the finished timer's time, or the moved entry (Change task).
    func choose(_ taskID: UUID, for request: TaskPickerRequest) {
        do {
            if let entryID = request.movingEntryID {
                show(.saved(try tasks.moveTimeEntry(id: entryID, to: taskID)))
            } else {
                show(try timer.save(request.timer, to: taskID))
            }
        } catch {
            Log.tasks.error("Couldn't save the timer's time: \(error)")
        }
        router.taskPicker = nil
    }

    // MARK: Confirmation

    func undo(_ toast: TimerToast) {
        guard let entry = toast.entry else { return }
        do {
            try tasks.undoTimerEntry(id: entry.id)
        } catch {
            Log.tasks.error("Couldn't undo the timer's entry: \(error)")
        }
        dismissToast()
    }

    /// Change task: opens the picker to move the entry to another habit.
    func changeTask(_ toast: TimerToast) {
        guard let entry = toast.entry else { return }
        dismissToast()
        router.taskPicker = TaskPickerRequest(
            timer: FinishedTimer(habitID: entry.taskID, day: entry.day, seconds: entry.seconds),
            movingEntryID: entry.id)
    }

    func dismissToast() {
        hideToast?.cancel()
        toast = nil
    }

    private func show(_ result: TimerSaveResult) {
        let message: String
        let entry: TimeEntryValue?
        switch result {
        case .tooShort:
            message = String(localized: "Less than a minute, nothing saved.")
            entry = nil
        case .saved(let saved):
            entry = saved
            message = confirmation(for: saved)
        }
        toast = TimerToast(message: message, entry: entry)
        hideToast?.cancel()
        hideToast = Task { [weak self] in
            try? await Task.sleep(for: Self.toastDuration)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    /// "Added 18 min to Read · 28 of 30 min today".
    private func confirmation(for entry: TimeEntryValue) -> String {
        guard let snapshot = try? tasks.snapshot(), let task = snapshot.engine.task(id: entry.taskID) else {
            return String(localized: "Added \(entry.seconds / 60) min")
        }
        let total = snapshot.activity.minutes(taskID: task.id, day: entry.day)
        let dayText =
            entry.day == tasks.today
            ? String(localized: "today") : DayTitleFormatter.shortDate(entry.day, calendar: tasks.calendar)
        if let target = snapshot.engine.schedule(for: task.id, on: entry.day)?.targetMinutes {
            return String(
                localized: "Added \(entry.seconds / 60) min to \(task.title) · \(total) of \(target) min \(dayText)")
        }
        return String(localized: "Added \(entry.seconds / 60) min to \(task.title)")
    }
}
