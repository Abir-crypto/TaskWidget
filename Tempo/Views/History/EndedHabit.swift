import Core
import Foundation

/// An ended habit in History, with its result (SPEC F-12).
struct EndedHabit: Identifiable, Hashable {
    let task: TaskValue
    /// "Done 27 of 30 days" or "On target 18 of 20 days · 14h 20m total".
    let result: String
    /// "Ended Thu 8 Oct".
    let ended: String

    var id: UUID { task.id }
}
