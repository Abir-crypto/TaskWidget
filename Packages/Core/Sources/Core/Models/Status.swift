/// The status of an occurrence (SPEC F-04, §5.4). Computed from the clock, never stored (D-012).
public enum Status: String, CaseIterable, Hashable, Codable, Sendable {
    /// Its part of the day hasn't started yet.
    case upcoming
    /// Its part of the day is in progress. Anytime tasks are Open all day.
    case open
    /// Completed, or a duration habit that reached its target.
    case done
    /// Duration only: its part ended with some minutes logged, but fewer than the target.
    case short
    /// Its part ended and it isn't done. For duration habits, no minutes were logged.
    case missed

    /// Done, Short and Missed don't change any more as time passes on that day.
    public var isFinal: Bool { self == .done || self == .short || self == .missed }

    /// Short counts as missed in the Missed tab, in counts and in stats (SPEC F-04).
    public var countsAsMissed: Bool { self == .short || self == .missed }

    /// Upcoming and Open: still to do.
    public var isPending: Bool { self == .upcoming || self == .open }
}
