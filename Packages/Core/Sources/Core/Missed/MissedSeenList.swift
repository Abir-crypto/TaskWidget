/// The missed tasks the popup has already shown today (SPEC F-08, §4.6). Kept on the device only.
public struct MissedSeenList: Hashable, Codable, Sendable {
    /// The day the list belongs to. A list for another day counts as empty.
    public var day: DayKey
    /// Occurrence ids, `<task_id>_<day>`.
    public var occurrenceIDs: Set<String>

    public init(day: DayKey, occurrenceIDs: Set<String> = []) {
        self.day = day
        self.occurrenceIDs = occurrenceIDs
    }
}
