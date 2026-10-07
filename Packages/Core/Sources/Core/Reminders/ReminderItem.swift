import Foundation

/// A task as a notification lists it: "Interview at 12:30", "Read (10 of 30 min)" (SPEC F-07).
public struct ReminderItem: Hashable, Sendable {
    public let taskID: UUID
    public let title: String
    /// The fixed time, for fixed-time tasks.
    public let fixedMinute: Int?
    /// Duration habits: minutes logged that day and the target.
    public let minutes: Int?
    public let targetMinutes: Int?

    public init(taskID: UUID, title: String, fixedMinute: Int?, minutes: Int?, targetMinutes: Int?) {
        self.taskID = taskID
        self.title = title
        self.fixedMinute = fixedMinute
        self.minutes = minutes
        self.targetMinutes = targetMinutes
    }
}
