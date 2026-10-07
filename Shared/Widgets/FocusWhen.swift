import Core
import Foundation

/// The Focus widget's top line (SPEC F-20): "NEXT · 12:30 · in 45 min", "NOON · until 17:00",
/// "EVENING · from 17:00" or "ANYTIME".
enum FocusWhen: Hashable {
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

    /// The line without the self-updating part: "NEXT · 12:30", "NOON · until 17:00", "EVENING · from 17:00",
    /// "ANYTIME".
    var label: String {
        switch self {
        case .next(let minute, _):
            "\(String(localized: "Next").localizedUppercase) · \(TimeOfDayFormatter.string(minute: minute))"
        case .currentPart(let part, let end):
            "\(part.title.localizedUppercase) · \(String(localized: "until \(TimeOfDayFormatter.string(minute: end))"))"
        case .laterPart(let part, let start):
            "\(part.title.localizedUppercase) · \(String(localized: "from \(TimeOfDayFormatter.string(minute: start))"))"
        case .anytime:
            String(localized: "Anytime").localizedUppercase
        }
    }
}
