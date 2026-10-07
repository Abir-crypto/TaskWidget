import Foundation

/// Input rules for creating and editing tasks (SPEC F-01, F-02, F-03, F-15, §7).
public enum TaskRules {
    /// Habit targets: 5–480 minutes in 5-minute steps, 30 by default.
    public static let targetRange = 5...480
    public static let targetStep = 5
    public static let defaultTarget = 30
    /// Set lengths: 1–365 days, 30 when switched on.
    public static let lengthRange = 1...365
    public static let defaultLength = 30
    /// Log time: 5–480 minutes in 5-minute steps (SPEC F-05).
    public static let logTimeRange = 5...480
    public static let logTimeStep = 5

    /// The title with leading and trailing spaces removed.
    public static func normalizedTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func titleError(_ title: String) -> TaskRuleError? {
        let trimmed = normalizedTitle(title)
        if trimmed.isEmpty { return .emptyTitle }
        if trimmed.count > TaskValue.maximumTitleLength { return .titleTooLong }
        return nil
    }

    public static func timingError(_ timing: Timing) -> TaskRuleError? {
        guard case .fixed(let minute) = timing else { return nil }
        let inDay = (0..<DayKey.minutesPerDay).contains(minute)
        return inDay && minute % Timing.fixedStep == 0 ? nil : .invalidFixedTime
    }

    public static func targetError(_ target: Int?, type: TaskType) -> TaskRuleError? {
        guard type == .duration else { return target == nil ? nil : .invalidTarget }
        guard let target, targetRange.contains(target), target % targetStep == 0 else { return .invalidTarget }
        return nil
    }

    public static func logTimeError(_ minutes: Int) -> TaskRuleError? {
        logTimeRange.contains(minutes) && minutes % logTimeStep == 0 ? nil : .invalidLogTime
    }

    public static func lengthError(_ length: Int?) -> TaskRuleError? {
        guard let length else { return nil }
        return lengthRange.contains(length) ? nil : .invalidLength
    }

    public static func weekdaysError(_ weekdays: Weekdays, type: TaskType) -> TaskRuleError? {
        guard type.isHabit else { return nil }
        let valid = !weekdays.isEmpty && weekdays.isSubset(of: .all)
        return valid ? nil : .noWeekdays
    }

    /// Whether a timing is already over on a day: its part has ended today, or the day is in the past. Anytime is
    /// over only on past days. New tasks can't be put there, since they'd be born missed (SPEC F-15, D-035).
    public static func isOver(_ timing: Timing, on day: DayKey, now: LocalTime, parts: PartSettings) -> Bool {
        if day != now.day { return day < now.day }
        switch timing {
        case .anytime: return false
        case .part(let part): return parts.end(of: part) <= now.minute
        case .fixed(let minute): return parts.end(of: parts.part(containing: minute)) <= now.minute
        }
    }

    /// The earliest fixed time that isn't in an ended part of `day` (SPEC F-15). 0 for future days.
    public static func earliestFixedMinute(on day: DayKey, now: LocalTime, parts: PartSettings) -> Int {
        guard day == now.day else { return 0 }
        let part = DayPart.allCases.first { parts.end(of: $0) > now.minute } ?? .night
        return part == .morning ? 0 : parts.start(of: part)
    }

    /// The first rule a new or edited schedule breaks, if any.
    public static func scheduleError(
        type: TaskType, timing: Timing, weekdays: Weekdays, targetMinutes: Int?
    ) -> TaskRuleError? {
        timingError(timing) ?? weekdaysError(weekdays, type: type) ?? targetError(targetMinutes, type: type)
    }
}

/// Why a task's input was rejected.
public enum TaskRuleError: Error, Hashable, Sendable {
    /// The title is empty after trimming spaces ("Add a title").
    case emptyTitle
    /// The title is longer than 100 characters.
    case titleTooLong
    /// A fixed time isn't a minute of the day on a 5-minute step.
    case invalidFixedTime
    /// A habit has no weekdays ("Pick at least one day").
    case noWeekdays
    /// A duration target isn't 5–480 in 5-minute steps, or a non-duration task has one.
    case invalidTarget
    /// A set length isn't 1–365 days.
    case invalidLength
    /// The date or start day is before today.
    case dayInPast
    /// Logged minutes aren't 5–480 in 5-minute steps.
    case invalidLogTime
    /// The part of the day has already ended today ("Already over").
    case partAlreadyOver
}
