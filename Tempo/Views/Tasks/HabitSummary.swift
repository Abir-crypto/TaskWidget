import Core
import Foundation

/// A habit as listed in Tasks › Habits (SPEC F-11).
struct HabitSummary: Identifiable, Hashable {
    let task: TaskValue
    /// "Mon, Wed, Fri · Evening".
    let schedule: String
    /// "4 of 5 this week", "Day 12 of 30", "2h 10m of 3h 30m this week" or "Starts Thu 8 Oct".
    let progress: String

    var id: UUID { task.id }
}
