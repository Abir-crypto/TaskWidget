import Core
import Foundation

/// Opens the Log time sheet for a duration habit (SPEC F-05, F-10). `day` is today unless it's set, for one of
/// yesterday's rows while it can still be corrected (SPEC §5.11).
struct LogTimeRequest: Identifiable, Hashable {
    let id = UUID()
    let taskID: UUID
    var day: DayKey?
}
