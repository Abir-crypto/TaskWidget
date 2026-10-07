import Core
import Foundation

/// One day's missed tasks in the Earlier section (SPEC F-08).
struct MissedGroup: Identifiable, Hashable {
    let day: DayKey
    /// "Tue 29 Sep".
    let title: String
    let items: [MissedItem]

    var id: Int { day.rawValue }
}
