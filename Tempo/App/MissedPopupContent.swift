import Core
import Foundation

/// What the missed popup shows: today's missed tasks it hasn't shown before (SPEC F-08).
struct MissedPopupContent: Identifiable, Hashable {
    let id = UUID()
    let items: [MissedItem]

    var occurrenceIDs: [String] { items.map(\.id) }
}
