/// The part-of-day choices in the Missed filter: the four parts and Anytime (SPEC F-08).
public enum MissedPartFilter: String, CaseIterable, Hashable, Codable, Sendable {
    case morning
    case noon
    case evening
    case night
    case anytime

    public init(_ part: DayPart?) {
        switch part {
        case .morning: self = .morning
        case .noon: self = .noon
        case .evening: self = .evening
        case .night: self = .night
        case nil: self = .anytime
        }
    }
}
