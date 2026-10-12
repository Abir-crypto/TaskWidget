import Core
import Foundation
import Observation

/// State for the Log time sheet (SPEC F-05): minutes to add to today, or to yesterday while it can still be corrected
/// (SPEC §5.11), 5–480 in 5-minute steps.
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
    /// The day the time goes to: today, unless the sheet was opened from one of yesterday's rows.
    private let requestedDay: DayKey?

    init(tasks: TaskManager, taskID: UUID, day: DayKey? = nil) {
        self.tasks = tasks
        self.taskID = taskID
        self.requestedDay = day
    }

    var day: DayKey { requestedDay ?? tasks.today }
    /// The sheet is for yesterday: its title and progress say so (SPEC F-10).
    var isForYesterday: Bool { day < tasks.today }

    /// Loads the habit and today's progress. The picker starts at the minutes left to reach today's target,
    /// rounded up to 5, or 30 once the target is reached (D-073).
    func load() {
        do {
            let snapshot = try tasks.snapshot()
            guard let task = snapshot.engine.task(id: taskID) else {
                errorMessage = String(localized: "This task no longer exists.")
                return
            }
            title = task.title
            minutesToday = snapshot.activity.minutes(taskID: taskID, day: day)
            targetMinutes = snapshot.engine.schedule(for: taskID, on: day)?.targetMinutes
            canLog = Editability.canLogTime(
                task: task, day: day, in: try tasks.editWindow(), calendar: tasks.calendar)
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
            try tasks.logTime(taskID: taskID, minutes: minutes, day: day)
            return true
        } catch {
            errorMessage = TaskEditorViewModel.message(for: error)
            return false
        }
    }
}
