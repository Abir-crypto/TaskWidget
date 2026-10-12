import Core

extension DayPart {
    /// The part's name: "Morning", "Afternoon", "Evening" or "Night". The part stored as `noon` is called Afternoon
    /// everywhere the user can see it (SPEC F-02, D-106).
    var title: String {
        switch self {
        case .morning: String(localized: "Morning", comment: "Part of the day")
        case .noon: String(localized: "Afternoon", comment: "Part of the day")
        case .evening: String(localized: "Evening", comment: "Part of the day")
        case .night: String(localized: "Night", comment: "Part of the day")
        }
    }
}
