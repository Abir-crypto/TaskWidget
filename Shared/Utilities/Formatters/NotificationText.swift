import Core
import Foundation

/// The words of each notification (SPEC F-07): "Afternoon · 3 tasks" / "Call the bank, Interview at 12:30, Read".
enum NotificationText {
    /// Lists show up to 3 names, then "and N more".
    static let maximumNames = 3

    /// The recap's title depends on the missed style (SPEC F-30); nothing else does.
    static func title(for content: ReminderContent, missedStyle: MissedStyle) -> String {
        switch content {
        case .partStart(_, let part, let items, let anytime):
            return "\(part.title) · \(inflected("^[\(items.count + anytime.count) task](inflect: true)"))"
        case .endingSoon(_, let part, let minutesLeft, _):
            return String(localized: "\(part.title) ends in \(minutesLeft) min")
        case .fixed(_, let item, _):
            return String(localized: "\(item.title) at \(TimeOfDayFormatter.string(minute: item.fixedMinute ?? 0))")
        case .recap(_, let missed, let open):
            return missedStyle.recapTitle(missed: missed.count, open: open.count)
        case .timerAlert(let habitTitle, _):
            guard let habitTitle else { return String(localized: "Timer is still running") }
            return String(localized: "\(habitTitle) timer is still running")
        }
    }

    static func body(for content: ReminderContent) -> String {
        switch content {
        case .partStart(_, _, let items, let anytime):
            guard !items.isEmpty else { return list(anytime.map { name($0, progress: false) }) }
            let names = list(items.map { name($0, progress: false) })
            guard !anytime.isEmpty else { return names }
            return String(localized: "\(names) …and \(anytime.count) anytime")
        case .endingSoon(_, _, _, let items):
            return String(localized: "\(items.count) left: \(list(items.map { name($0, progress: true) }))")
        case .fixed(_, _, let lead):
            return String(localized: "In \(lead) min")
        case .recap(_, let missed, let open):
            return list((missed + open).map { name($0, progress: true) })
        case .timerAlert(_, let minutes):
            return inflected("It's been running for ^[\(minutes / 60) hour](inflect: true).")
        }
    }

    /// "Interview at 12:30", "Read (10 of 30 min)" or just the title.
    static func name(_ item: ReminderItem, progress: Bool) -> String {
        if progress, let minutes = item.minutes, let target = item.targetMinutes {
            return "\(item.title) (\(DurationFormatter.progress(minutes: minutes, target: target)))"
        }
        if let minute = item.fixedMinute {
            return String(localized: "\(item.title) at \(TimeOfDayFormatter.string(minute: minute))")
        }
        return item.title
    }

    /// "A, B, C" or "A, B, C and 2 more".
    static func list(_ names: [String]) -> String {
        let shown = names.prefix(maximumNames).joined(separator: ", ")
        let more = names.count - maximumNames
        return more > 0 ? String(localized: "\(shown) and \(more) more") : shown
    }

    /// Applies automatic grammar agreement ("1 task", "2 tasks") to a localized string.
    private static func inflected(_ value: String.LocalizationValue) -> String {
        String(AttributedString(localized: value).characters)
    }

    /// The link a notification opens (SPEC F-07, ios.md §11).
    static func url(for destination: ReminderDestination) -> URL {
        switch destination {
        case .today(let day, let part, let taskID): DeepLink.today(day: day, part: part, taskID: taskID).url
        case .missed: DeepLink.missed.url
        case .timer: DeepLink.timer.url
        }
    }
}
