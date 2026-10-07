import Core
import Foundation
import Observation

/// State for the Log time sheet (SPEC F-05): minutes to add to today, 5–480 in 5-minute steps.
@Observable
@MainActor
final class LogTimeViewModel {
    var minutes = TaskRules.defaultTarget
    private(set) var title = ""
    private(set) var minutesToday = 0
    private(set) var targetMinutes: Int?
    private(set) var canLog = false
    var errorMessage: String?

    let choices = Array(
        stride(
            from: TaskRules.logTimeRange.lowerBound, through: TaskRules.logTimeRange.upperBound,
            by: TaskRules.logTimeStep))

    private let tasks: TaskManager
    private let taskID: UUID

    init(tasks: TaskManager, taskID: UUID) {
        self.tasks = tasks
        self.taskID = taskID
    }

    /// Loads the habit and today's progress. The picker starts at the minutes left to reach today's target,
    /// rounded up to 5, or 30 once the target is reached (D-073).
    func load() {
        do {
            let snapshot = try tasks.snapshot()
            guard let task = snapshot.engine.task(id: taskID) else {
                errorMessage = String(localized: "This task no longer exists.")
                return
            }
            let today = tasks.today
            title = task.title
            minutesToday = snapshot.activity.minutes(taskID: taskID, day: today)
            targetMinutes = snapshot.engine.schedule(for: taskID, on: today)?.targetMinutes
            canLog = Editability.canLogTime(task: task, day: today, today: today, calendar: tasks.calendar)
            let left = (targetMinutes ?? 0) - minutesToday
            let rounded = (left + TaskRules.logTimeStep - 1) / TaskRules.logTimeStep * TaskRules.logTimeStep
            minutes =
                left > 0
                ? min(max(rounded, TaskRules.logTimeRange.lowerBound), TaskRules.logTimeRange.upperBound)
                : TaskRules.defaultTarget
        } catch {
            errorMessage = String(localized: "This task couldn't be loaded.")
        }
    }

    /// Adds the entry. Returns `true` when the sheet can close.
    @discardableResult
    func save() -> Bool {
        do {
            try tasks.logTime(taskID: taskID, minutes: minutes)
            return true
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
            return false
        }
    }
}
