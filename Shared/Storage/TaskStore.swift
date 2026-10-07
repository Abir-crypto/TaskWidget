import Core
import Foundation

/// The storage interface the rest of the app uses (ios.md §4). It speaks `Core` value types only.
///
/// Reads never return soft-deleted rows. Every write sets `updatedAt` to the store's clock, and deletes are
/// soft: they set `deletedAt` (SPEC F-26).
protocol TaskStore: Sendable {
    /// Every live row of the four task tables, read together.
    func loadAll() throws -> TaskData

    func tasks() throws -> [TaskValue]
    func task(id: UUID) throws -> TaskValue?
    /// Inserts or updates by `id`, and returns the stored copy.
    @discardableResult func save(_ task: TaskValue) throws -> TaskValue
    func softDeleteTask(id: UUID) throws

    func schedules(taskID: UUID?) throws -> [ScheduleValue]
    @discardableResult func save(_ schedule: ScheduleValue) throws -> ScheduleValue
    func softDeleteSchedule(id: UUID) throws

    func completions(taskID: UUID?) throws -> [CompletionValue]
    @discardableResult func save(_ completion: CompletionValue) throws -> CompletionValue
    func softDeleteCompletion(id: UUID) throws

    func timeEntries(taskID: UUID?) throws -> [TimeEntryValue]
    @discardableResult func save(_ entry: TimeEntryValue) throws -> TimeEntryValue
    func softDeleteTimeEntry(id: UUID) throws

    /// The settings row, or `nil` before it has been created.
    func settings() throws -> SettingsValue?
    @discardableResult func save(_ settings: SettingsValue) throws -> SettingsValue
}
