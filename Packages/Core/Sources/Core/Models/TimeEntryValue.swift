import Foundation

/// A row of the `time_entries` table (SPEC §4.4): seconds logged to a duration habit on a day.
public struct TimeEntryValue: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var taskID: UUID
    public var day: DayKey
    /// Always greater than 0.
    public var seconds: Int
    public var source: TimeEntrySource
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        taskID: UUID,
        day: DayKey,
        seconds: Int,
        source: TimeEntrySource,
        createdAt: Date,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.taskID = taskID
        self.day = day
        self.seconds = seconds
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.deletedAt = deletedAt
    }
}
