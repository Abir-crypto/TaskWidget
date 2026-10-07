import Core
import Foundation

/// The one-time tasks completed on one day.
struct CompletedGroup: Identifiable, Hashable {
    let day: DayKey
    /// "Today", "Yesterday" or "Thu 8 Oct".
    let title: String
    let tasks: [CompletedTask]

    var id: Int { day.rawValue }
}
