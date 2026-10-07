import Foundation

/// Opens the Log time sheet for a duration habit (SPEC F-05, F-10).
struct LogTimeRequest: Identifiable, Hashable {
    let id = UUID()
    let taskID: UUID
}
