import Core
import Foundation
import Observation

/// State for the task picker (SPEC F-06): the duration habits a finished timer's time can go to.
@Observable
@MainActor
final class TaskPickerViewModel {
    private(set) var habits: [PickerHabit] = []
    private(set) var isLoaded = false

    let request: TaskPickerRequest
    private let tasks: TaskManager

    init(tasks: TaskManager, request: TaskPickerRequest) {
        self.tasks = tasks
        self.request = request
    }

    var isMoving: Bool { request.movingEntryID != nil }

    /// Duration habits live on the timer's day (today, unless it ran past midnight). Those scheduled that day
    /// and below their target come first, then the rest, each in creation order. When moving an entry, its
    /// current habit isn't offered.
    func load() {
        do {
            let snapshot = try tasks.snapshot()
            let day = request.timer.day
            var first: [PickerHabit] = []
            var rest: [PickerHabit] = []
            for task in snapshot.engine.tasks where task.type == .duration && snapshot.engine.isLive(task, on: day) {
                if isMoving, task.id == request.timer.habitID { continue }
                let minutes = snapshot.activity.minutes(taskID: task.id, day: day)
                let occurrence = snapshot.engine.occurrence(of: task, on: day)
                let target = occurrence?.schedule.targetMinutes
                let progress =
                    target.map { DurationFormatter.progress(minutes: minutes, target: $0) }
                    ?? String(localized: "\(minutes) min")
                let needsTime = target.map { minutes < $0 } ?? false
                let habit = PickerHabit(task: task, progress: progress, needsTime: needsTime)
                if needsTime { first.append(habit) } else { rest.append(habit) }
            }
            habits = first + rest
            isLoaded = true
        } catch {
            Log.tasks.error("Couldn't load the task picker: \(error)")
        }
    }

    /// "18 min", the time being saved.
    var timeText: String {
        String(localized: "\(request.timer.seconds / 60) min")
    }
}
