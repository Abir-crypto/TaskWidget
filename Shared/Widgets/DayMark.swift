import Core

/// One task's mark in the Day widget (SPEC F-19): ✓ done, ○ not done yet, ✗ missed, ◐ short or partly timed.
enum DayMark: Hashable {
    case done
    case notDone
    case missed
    case partial

    init(_ item: DayItem) {
        switch item.status {
        case .done: self = .done
        case .missed: self = .missed
        case .short: self = .partial
        case .upcoming, .open: self = item.minutes > 0 ? .partial : .notDone
        }
    }

    var systemImage: String {
        switch self {
        case .done: "checkmark.circle.fill"
        case .notDone: "circle"
        case .missed: "xmark.circle"
        case .partial: "circle.lefthalf.filled"
        }
    }
}
