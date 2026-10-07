/// The result of the next-task rule (SPEC §5.6): what's next, and why, which decides its "when" line.
public struct NextTask: Hashable, Sendable {
    public let occurrence: Occurrence
    public let kind: NextTaskKind

    public init(occurrence: Occurrence, kind: NextTaskKind) {
        self.occurrence = occurrence
        self.kind = kind
    }
}

/// Why the next-task rule chose an item, which is what the Focus and Lock Screen widgets describe.
public enum NextTaskKind: Hashable, Sendable {
    /// A fixed-time task, shown with its time ("NEXT · 12:30 · in 45 min"). Rules 1 and 3.
    case fixed(minute: Int)
    /// A task in the part in progress ("NOON · until 17:00"). Rule 2.
    case currentPart(DayPart)
    /// A part-of-day task in a later part ("EVENING · from 17:00"). Rule 3.
    case laterPart(DayPart)
    /// An Anytime task ("ANYTIME"). Rule 4.
    case anytime
}
