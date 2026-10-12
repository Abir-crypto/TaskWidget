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

    /// A missed day is a cross in the Strict style and a dash in the Gentle style (SPEC F-30).
    func systemImage(_ style: MissedStyle) -> String {
        switch self {
        case .done: "checkmark.circle.fill"
        case .short: "circle.lefthalf.filled"
        case .missed: style == .strict ? "xmark.circle.fill" : "minus.circle.fill"
        case .upcoming: "circle"
        case .notScheduled: "minus"
        }
    }

    func label(_ style: MissedStyle) -> String {
        switch self {
        case .done: String(localized: "Done")
        case .short: String(localized: "Short")
        case .missed: style.statusTitle
        case .upcoming: String(localized: "Upcoming")
        case .notScheduled: String(localized: "Not scheduled")
        }
    }
}
