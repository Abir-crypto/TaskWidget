import Core
import Foundation

/// A completed one-time task in History (SPEC F-12).
struct CompletedTask: Identifiable, Hashable {
    let task: TaskValue
    /// The day the task was completed, from the completion's time (D-079).
    let completedOn: DayKey
    let completedAt: Date
    /// Only tasks completed today can be marked not done.
    let canUndo: Bool

    var id: UUID { task.id }
}
