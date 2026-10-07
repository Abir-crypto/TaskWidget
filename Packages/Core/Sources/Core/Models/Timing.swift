/// When in the day a task belongs (SPEC F-02).
public enum Timing: Hashable, Codable, Sendable {
    /// A fixed time, as a minute of day in 5-minute steps.
    case fixed(minute: Int)
    /// One of the four parts of the day.
    case part(DayPart)
    /// Any time today; belongs to no part.
    case anytime

    /// Fixed times use 5-minute steps (SPEC F-02).
    public static let fixedStep = 5

    /// The stored `timing` value from SPEC §4.2.
    public var kind: TimingKind {
        switch self {
        case .fixed: .fixed
        case .part: .part
        case .anytime: .anytime
        }
    }

    /// The fixed minute, when the timing is fixed.
    public var fixedMinute: Int? {
        if case .fixed(let minute) = self { return minute }
        return nil
    }

    /// The part, when the timing is a part of the day.
    public var part: DayPart? {
        if case .part(let part) = self { return part }
        return nil
    }

    /// Rebuilds a timing from its stored columns. Returns `nil` when they don't fit together.
    public init?(kind: TimingKind, fixedMinute: Int?, part: DayPart?) {
        switch kind {
        case .fixed:
            guard let fixedMinute else { return nil }
            self = .fixed(minute: fixedMinute)
        case .part:
            guard let part else { return nil }
            self = .part(part)
        case .anytime:
            self = .anytime
        }
    }
}

/// The stored strings for a schedule's `timing` column (SPEC §4.2).
public enum TimingKind: String, CaseIterable, Codable, Sendable {
    case fixed
    case part
    case anytime
}
