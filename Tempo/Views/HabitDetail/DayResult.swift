import Core

/// How a day looks in Habit detail's week dots and month calendar (SPEC F-13).
enum DayResult: Hashable {
    case done
    case short
    case missed
    /// Scheduled and not over yet, including today while it's open.
    case upcoming
    case notScheduled

    init(_ status: Status?) {
        switch status {
        case .done: self = .done
        case .short: self = .short
        case .missed: self = .missed
        case .upcoming, .open: self = .upcoming
        case nil: self = .notScheduled
        }
    }

    var systemImage: String {
        switch self {
        case .done: "checkmark.circle.fill"
        case .short: "circle.lefthalf.filled"
        case .missed: "xmark.circle.fill"
        case .upcoming: "circle"
        case .notScheduled: "minus"
        }
    }

    var label: String {
        switch self {
        case .done: String(localized: "Done")
        case .short: String(localized: "Short")
        case .missed: String(localized: "Missed")
        case .upcoming: String(localized: "Upcoming")
        case .notScheduled: String(localized: "Not scheduled")
        }
    }
}
