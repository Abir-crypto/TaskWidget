import Foundation

/// A row of the `tasks` table (SPEC §4.1).
public struct TaskValue: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    /// 1–100 characters after trimming spaces (SPEC F-01).
    public var title: String
    public var type: TaskType
    /// One-time tasks: the task's day.
    public var date: DayKey?
    /// Habits: the first day.
    public var startDay: DayKey?
    /// Habits: the set length in calendar days, or `nil` for ongoing.
    public var lengthDays: Int?
    /// Habits: the last day, when ended by hand.
    public var endedOn: DayKey?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        type: TaskType,
        date: DayKey? = nil,
        startDay: DayKey? = nil,
        lengthDays: Int? = nil,
        endedOn: DayKey? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.date = date
        self.startDay = startDay
        self.lengthDays = lengthDays
        self.endedOn = endedOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.deletedAt = deletedAt
    }

    /// Titles are 1–100 characters (SPEC §7).
    public static let maximumTitleLength = 100

    /// A habit's last day: the earlier of `start_day + length_days − 1` and `ended_on` (SPEC §4.1).
    /// `nil` when the habit has no last day. A one-time task's last day is its date.
    public func lastDay(in calendar: Calendar) -> DayKey? {
        guard type.isHabit else { return date }
        let lengthEnd: DayKey? =
            if let startDay, let lengthDays { startDay.adding(days: lengthDays - 1, in: calendar) } else { nil }
        switch (lengthEnd, endedOn) {
        case (let end?, let ended?): return min(end, ended)
        case (let end?, nil): return end
        case (nil, let ended?): return ended
        case (nil, nil): return nil
        }
    }

    /// Whether the habit has ended by `today`: its last day is before today (SPEC F-03).
    public func hasEnded(today: DayKey, calendar: Calendar) -> Bool {
        guard type.isHabit, let last = lastDay(in: calendar) else { return false }
        return last < today
    }
}
