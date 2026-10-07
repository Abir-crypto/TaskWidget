/// One occurrence in a day's plan, with what's needed to show it.
public struct DayItem: Identifiable, Hashable, Sendable {
    public let occurrence: Occurrence
    public let status: Status
    /// Duration habits: minutes logged that day.
    public let minutes: Int
    /// Duration habits: that day's target.
    public let targetMinutes: Int?

    public init(occurrence: Occurrence, status: Status, minutes: Int, targetMinutes: Int?) {
        self.occurrence = occurrence
        self.status = status
        self.minutes = minutes
        self.targetMinutes = targetMinutes
    }

    public var id: String { occurrence.id }
    public var task: TaskValue { occurrence.task }
}
