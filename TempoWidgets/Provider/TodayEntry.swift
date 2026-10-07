import Foundation
import WidgetKit

/// One moment of a widget's timeline. `snapshot` is `nil` when the data couldn't be loaded (SPEC F-17).
struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    static func failed(_ date: Date) -> TodayEntry {
        TodayEntry(date: date, snapshot: nil)
    }
}
