/// Where a section of a day stands relative to now (SPEC F-10).
public enum DaySectionPhase: Hashable, Sendable {
    /// Today: the part has ended. Collapsed on the Today screen.
    case ended
    /// Today: the part in progress. Highlighted, with "ends in …".
    case current
    /// Today: the part hasn't started.
    case upcoming
    /// The Anytime section on today: open all day.
    case anytime
    /// A day before today: everything is final.
    case past
    /// A day after today.
    case future
}
