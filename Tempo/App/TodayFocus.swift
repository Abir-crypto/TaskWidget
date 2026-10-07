import Core
import Foundation

/// Where a link asked Today to open: a day, a part, a task (SPEC F-09). Each request has its own id, so the
/// same place can be asked for twice.
struct TodayFocus: Identifiable, Hashable {
    let id = UUID()
    var day: DayKey?
    var part: DayPart?
    var taskID: UUID?
}
