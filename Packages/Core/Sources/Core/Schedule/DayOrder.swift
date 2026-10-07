/// The order tasks are listed in within a day (SPEC F-10): Morning, Noon, Evening, Night, then Anytime.
/// Within a part, fixed-time tasks come first in time order, then part-of-day tasks in creation order.
public enum DayOrder {
    /// Sorts occurrences of one day. Ties keep their incoming order, which is creation order from `ScheduleEngine`.
    public static func sorted(_ occurrences: [Occurrence], parts: PartSettings) -> [Occurrence] {
        occurrences.enumerated()
            .sorted { lhs, rhs in
                let left = key(lhs.element, parts: parts)
                let right = key(rhs.element, parts: parts)
                return (left.section, left.partOfDay, left.minute, lhs.offset)
                    < (right.section, right.partOfDay, right.minute, rhs.offset)
            }
            .map(\.element)
    }

    /// Section index (0–3 for the parts, 4 for Anytime), then fixed before part-of-day, then the fixed minute.
    private static func key(
        _ occurrence: Occurrence, parts: PartSettings
    ) -> (section: Int, partOfDay: Int, minute: Int) {
        let section = occurrence.part(parts: parts).map { DayPart.allCases.firstIndex(of: $0) ?? 0 } ?? 4
        switch occurrence.timing {
        case .fixed(let minute): return (section, 0, minute)
        case .part, .anytime: return (section, 1, 0)
        }
    }
}
