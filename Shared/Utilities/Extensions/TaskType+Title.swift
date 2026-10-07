import Core

extension TaskType {
    /// "One-time", "Progress" or "Duration".
    var title: String {
        switch self {
        case .oneTime: String(localized: "One-time", comment: "Task type")
        case .progress: String(localized: "Progress", comment: "Task type")
        case .duration: String(localized: "Duration", comment: "Task type")
        }
    }

    /// One sentence on what the type is for.
    var explanation: String {
        switch self {
        case .oneTime: String(localized: "Done once, on one day.")
        case .progress: String(localized: "A habit you check off on the days it repeats.")
        case .duration: String(localized: "A habit measured in minutes against a daily target.")
        }
    }

    /// The SF Symbol shown next to tasks of this type.
    var systemImage: String {
        switch self {
        case .oneTime: "circle"
        case .progress: "checkmark.circle"
        case .duration: "timer"
        }
    }
}
