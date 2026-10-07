import Foundation

/// One notification in the plan (SPEC §5.9): its id, when it fires, and what it's about.
public struct PlannedNotification: Hashable, Sendable {
    /// `part-start.<day>.<part>`, `ending-soon.<day>.<part>`, `fixed.<task_id>.<day>`, `recap.<day>` or
    /// `timer-alert`.
    public let id: String
    public let fireDate: Date
    public let content: ReminderContent

    public init(id: String, fireDate: Date, content: ReminderContent) {
        self.id = id
        self.fireDate = fireDate
        self.content = content
    }
}
