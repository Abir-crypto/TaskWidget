import Core
import Foundation

/// A task the Focus widget points at (SPEC F-20).
struct FocusItem: Hashable {
    let taskID: UUID
    let day: DayKey
    let title: String
    let when: FocusWhen
    /// Duration habits: "10 of 30 min".
    let progress: String?

    init(_ next: NextTask, snapshot: Snapshot) {
        let occurrence = next.occurrence
        taskID = occurrence.task.id
        day = occurrence.day
        title = occurrence.task.title
        when = FocusWhen(next.kind, day: occurrence.day, parts: snapshot.parts, calendar: snapshot.calendar)
        if occurrence.type == .duration, let target = occurrence.schedule.targetMinutes {
            progress = DurationFormatter.progress(minutes: snapshot.statusRules.minutes(of: occurrence), target: target)
        } else {
            progress = nil
        }
    }

    /// Opens Today at this task.
    var url: URL { DeepLink.today(day: day, taskID: taskID).url }
}
