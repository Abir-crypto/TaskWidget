/// The three kinds of task (SPEC F-01). Raw values are the stored strings from SPEC §4.1.
public enum TaskType: String, CaseIterable, Codable, Sendable {
    case oneTime = "one_time"
    case progress
    case duration

    /// Progress and duration tasks are habits: they repeat and carry goals.
    public var isHabit: Bool { self != .oneTime }
}
