import Core
import Foundation

/// A task the next-task rule points at, as the Focus and Lock Screen widgets show it (SPEC F-20, F-22).
struct NextTaskItem: Hashable {
    let taskID: UUID
    let day: DayKey
    let title: String
    let when: NextTaskWhen
    /// Duration habits: "10 of 30 min".
    let progress: String?

    init(_ next: NextTask, snapshot: Snapshot) {
        let occurrence = next.occurrence
        taskID = occurrence.task.id
        day = occurrence.day
        title = occurrence.task.title
        when = NextTaskWhen(next.kind, day: occurrence.day, parts: snapshot.parts, calendar: snapshot.calendar)
        if occurrence.type == .duration, let target = occurrence.schedule.targetMinutes {
            progress = DurationFormatter.progress(minutes: snapshot.statusRules.minutes(of: occurrence), target: target)
        } else {
            progress = nil
        }
    }

    /// Opens Today at this task.
    var url: URL { DeepLink.today(day: day, taskID: taskID).url }
}
