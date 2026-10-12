/// How long a reminder can be snoozed for (SPEC F-07): 15 minutes or 1 hour.
public enum SnoozeOption: Int, CaseIterable, Codable, Hashable, Sendable {
    case fifteenMinutes = 15
    case oneHour = 60

    public var minutes: Int { rawValue }
}
