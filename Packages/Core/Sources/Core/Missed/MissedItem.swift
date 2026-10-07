/// A Missed or Short occurrence, as listed in the Missed tab (SPEC F-08).
public struct MissedItem: Identifiable, Hashable, Sendable {
    public let occurrence: Occurrence
    /// `.missed` or `.short`.
    public let status: Status
    /// Duration habits: the minutes logged that day.
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
    public var day: DayKey { occurrence.day }
}
