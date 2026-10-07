import Core
import Foundation

/// A duration habit offered by the task picker, with its progress that day (SPEC F-06).
struct PickerHabit: Identifiable, Hashable {
    let task: TaskValue
    /// "10 of 30 min", or "35 min" on a day the habit isn't scheduled.
    let progress: String
    /// Scheduled that day and still below its target: listed first.
    let needsTime: Bool

    var id: UUID { task.id }
}
