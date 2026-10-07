import Core
import Foundation

/// One date's upcoming one-time tasks in Tasks › One-time (SPEC F-11).
struct OneTimeGroup: Identifiable, Hashable {
    let day: DayKey
    /// "Today", "Tomorrow" or "Thu 8 Oct".
    let title: String
    let items: [DayItem]

    var id: Int { day.rawValue }
}
