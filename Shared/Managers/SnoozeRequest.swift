import Core
import Foundation

/// A Snooze button tapped on a fixed-time or ending-soon notification (SPEC F-07): which reminder, when its part
/// ends, and for how long. Read from the notification's `userInfo`, where `SystemNotificationScheduler` wrote it.
struct SnoozeRequest: Hashable, Sendable {
    let originalID: String
    let kind: SnoozeKind
    let day: DayKey
    let partEnd: Date
    let option: SnoozeOption

    /// The `userInfo` keys a snoozable notification carries.
    enum Key {
        static let originalID = "snoozeOriginalID"
        static let kind = "snoozeKind"
        static let day = "snoozeDay"
        static let partEnd = "snoozePartEnd"
    }

    /// The `userInfo` entries for a snoozable notification.
    static func userInfo(for target: SnoozeTarget) -> [String: Any] {
        [
            Key.originalID: target.originalID, Key.kind: target.kind.rawValue, Key.day: target.day.rawValue,
            Key.partEnd: target.partEnd.timeIntervalSince1970,
        ]
    }

    /// Reads a Snooze tap, or `nil` for any other action or a notification without snooze details.
    init?(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        let option: SnoozeOption
        switch actionIdentifier {
        case NotificationCategory.snooze15: option = .fifteenMinutes
        case NotificationCategory.snooze60: option = .oneHour
        default: return nil
        }
        guard let originalID = userInfo[Key.originalID] as? String,
            let kind = (userInfo[Key.kind] as? String).flatMap(SnoozeKind.init(rawValue:)),
            let day = userInfo[Key.day] as? Int,
            let partEnd = userInfo[Key.partEnd] as? Double
        else { return nil }
        self.originalID = originalID
        self.kind = kind
        self.day = DayKey(rawValue: day)
        self.partEnd = Date(timeIntervalSince1970: partEnd)
        self.option = option
    }
}
