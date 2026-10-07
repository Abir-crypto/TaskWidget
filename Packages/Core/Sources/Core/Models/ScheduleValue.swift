import Foundation

/// A row of the `schedules` table (SPEC §4.2): a task's timing, weekdays and target from a given day onward.
public struct ScheduleValue: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var taskID: UUID
    /// The first day this schedule applies to. Always `DayKey.distantPast` (0) for one-time tasks.
    public var effectiveFrom: DayKey
    public var timing: Timing
    /// Habits: the scheduled weekdays. One-time tasks: `.none`.
    public var weekdays: Weekdays
    /// Duration habits: the daily target in minutes.
    public var targetMinutes: Int?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        taskID: UUID,
        effectiveFrom: DayKey,
        timing: Timing,
        weekdays: Weekdays,
        targetMinutes: Int? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.taskID = taskID
        self.effectiveFrom = effectiveFrom
        self.timing = timing
        self.weekdays = weekdays
        self.targetMinutes = targetMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.deletedAt = deletedAt
    }
}
