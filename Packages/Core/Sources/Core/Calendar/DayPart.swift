/// One of the four parts of the day (SPEC F-02). Raw values are the stored strings from SPEC §4.2.
public enum DayPart: String, CaseIterable, Codable, Sendable, Comparable {
    case morning
    case noon
    case evening
    case night

    /// The part that follows this one, or `nil` for Night.
    public var next: DayPart? {
        switch self {
        case .morning: .noon
        case .noon: .evening
        case .evening: .night
        case .night: nil
        }
    }

    public static func < (lhs: DayPart, rhs: DayPart) -> Bool {
        lhs.order < rhs.order
    }

    private var order: Int {
        switch self {
        case .morning: 0
        case .noon: 1
        case .evening: 2
        case .night: 3
        }
    }
}
