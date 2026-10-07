import Core

extension DayPart {
    /// The part's name: "Morning", "Noon", "Evening" or "Night".
    var title: String {
        switch self {
        case .morning: String(localized: "Morning", comment: "Part of the day")
        case .noon: String(localized: "Noon", comment: "Part of the day")
        case .evening: String(localized: "Evening", comment: "Part of the day")
        case .night: String(localized: "Night", comment: "Part of the day")
        }
    }
}
