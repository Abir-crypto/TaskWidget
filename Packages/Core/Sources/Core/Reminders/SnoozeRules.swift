import Foundation

/// When snoozing is offered and when a snoozed reminder fires (SPEC F-07, D-110, D-122).
public enum SnoozeRules {
    /// A snoozed reminder lands at least this long before its part ends.
    public static let marginMinutes = 5

    /// The latest moment a reminder for a part ending at `partEnd` can be snoozed to.
    public static func latestFireDate(partEnd: Date) -> Date {
        partEnd.addingTimeInterval(TimeInterval(-marginMinutes * 60))
    }

    /// The options a reminder offers, judged from its planned fire time: each one has to land at least 5 minutes
    /// before the part ends.
    public static func options(firingAt fireDate: Date, partEnd: Date) -> [SnoozeOption] {
        let latest = latestFireDate(partEnd: partEnd)
        return SnoozeOption.allCases.filter { fireDate.addingTimeInterval(TimeInterval($0.minutes * 60)) <= latest }
    }

    /// When a snooze tapped at `tapDate` fires: the tap plus the option, but never later than 5 minutes before the
    /// part ends. `nil` when that moment has already passed, so nothing is scheduled (D-122).
    public static func fireDate(tappedAt tapDate: Date, option: SnoozeOption, partEnd: Date) -> Date? {
        let fire = min(tapDate.addingTimeInterval(TimeInterval(option.minutes * 60)), latestFireDate(partEnd: partEnd))
        return fire > tapDate ? fire : nil
    }
}
