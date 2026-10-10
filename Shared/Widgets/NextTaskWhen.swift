import Core
import Foundation

/// Why the next-task rule chose an item, with the times the Focus and Lock Screen widgets show (SPEC F-20, F-22).
enum NextTaskWhen: Hashable {
    /// A fixed-time task, at this minute; `date` is the real moment, for the self-updating "in 45 min".
    case next(minute: Int, date: Date)
    /// A task in the part in progress, which ends at this minute.
    case currentPart(DayPart, endMinute: Int)
    /// A task in a later part, which starts at this minute.
    case laterPart(DayPart, startMinute: Int)
    case anytime

    init(_ kind: NextTaskKind, day: DayKey, parts: PartSettings, calendar: Calendar) {
        switch kind {
        case .fixed(let minute):
            self = .next(minute: minute, date: day.date(atMinute: minute, in: calendar))
        case .currentPart(let part):
            self = .currentPart(part, endMinute: parts.end(of: part))
        case .laterPart(let part):
            self = .laterPart(part, startMinute: parts.start(of: part))
        case .anytime:
            self = .anytime
        }
    }

    /// The Focus widget's top line without the self-updating part: "NEXT · 12:30", "NOON · until 17:00",
    /// "EVENING · from 17:00", "ANYTIME".
    var focusLabel: String {
        switch self {
        case .next(let minute, _):
            "\(String(localized: "Next").localizedUppercase) · \(TimeOfDayFormatter.string(minute: minute))"
        case .currentPart(let part, _), .laterPart(let part, _):
            "\(part.title.localizedUppercase) · \(timeRange)"
        case .anytime:
            String(localized: "Anytime").localizedUppercase
        }
    }

    /// Where the item sits in the day: its time, its part, or "Anytime".
    var place: String {
        switch self {
        case .next(let minute, _): TimeOfDayFormatter.string(minute: minute)
        case .currentPart(let part, _), .laterPart(let part, _): part.title
        case .anytime: String(localized: "Anytime")
        }
    }

    /// "until 17:00" for the part in progress, "from 17:00" for a later part, otherwise empty.
    var timeRange: String {
        switch self {
        case .currentPart(_, let end): String(localized: "until \(TimeOfDayFormatter.string(minute: end))")
        case .laterPart(_, let start): String(localized: "from \(TimeOfDayFormatter.string(minute: start))")
        case .next, .anytime: ""
        }
    }
}
