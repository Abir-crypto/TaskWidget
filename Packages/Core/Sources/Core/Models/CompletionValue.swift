import Foundation

/// A row of the `completions` table (SPEC §4.3): a one-time task or progress habit done on a day.
public struct CompletionValue: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var taskID: UUID
    /// For one-time tasks, the task's date.
    public var day: DayKey
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        taskID: UUID,
        day: DayKey,
        createdAt: Date,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.taskID = taskID
        self.day = day
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.deletedAt = deletedAt
    }
}
