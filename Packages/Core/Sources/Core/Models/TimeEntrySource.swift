/// Where a time entry came from (SPEC §4.4).
public enum TimeEntrySource: String, CaseIterable, Codable, Sendable {
    case timer
    case manual
}
