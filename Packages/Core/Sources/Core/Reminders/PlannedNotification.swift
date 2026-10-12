import Foundation

/// One notification in the plan (SPEC §5.9): its id, when it fires, what it's about, and its Snooze buttons.
public struct PlannedNotification: Hashable, Sendable {
    /// `part-start.<day>.<part>`, `ending-soon.<day>.<part>`, `fixed.<task_id>.<day>`, `recap.<day>`,
    /// `timer-alert`, or `snooze.` followed by a fixed-time or ending-soon id.
    public let id: String
    public let fireDate: Date
    public let content: ReminderContent
    /// Fixed-time and ending-soon reminders can be snoozed; nothing else can (SPEC F-07).
    public let snooze: SnoozeTarget?

    public init(id: String, fireDate: Date, content: ReminderContent, snooze: SnoozeTarget? = nil) {
        self.id = id
        self.fireDate = fireDate
        self.content = content
        self.snooze = snooze
    }
}
