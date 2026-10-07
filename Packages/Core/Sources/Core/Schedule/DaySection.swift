/// A part of the day, or Anytime, with its items in display order (SPEC F-10).
public struct DaySection: Identifiable, Hashable, Sendable {
    /// `nil` for Anytime.
    public let part: DayPart?
    public let phase: DaySectionPhase
    /// Minutes of the day the section covers: the part's window, or the whole day for Anytime.
    public let window: Range<Int>
    public let items: [DayItem]

    public init(part: DayPart?, phase: DaySectionPhase, window: Range<Int>, items: [DayItem]) {
        self.part = part
        self.phase = phase
        self.window = window
        self.items = items
    }

    public var id: String { part?.rawValue ?? "anytime" }

    /// Items that are done.
    public var doneCount: Int { items.filter { $0.status == .done }.count }
    /// Items that are Missed or Short.
    public var missedCount: Int { items.filter { $0.status.countsAsMissed }.count }
    /// Items still Upcoming or Open.
    public var leftCount: Int { items.filter { $0.status.isPending }.count }
}
