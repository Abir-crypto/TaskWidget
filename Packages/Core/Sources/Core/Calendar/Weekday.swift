/// A day of the week. Raw values follow the bit order of SPEC §4.2 (Monday first).
public enum Weekday: Int, CaseIterable, Codable, Sendable {
    case monday = 0
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    /// Converts `Calendar`'s weekday number, where 1 is Sunday and 7 is Saturday.
    public init?(calendarWeekday: Int) {
        guard (1...7).contains(calendarWeekday) else { return nil }
        self.init(rawValue: (calendarWeekday + 5) % 7)
    }

    /// `Calendar`'s weekday number, where 1 is Sunday and 7 is Saturday.
    public var calendarWeekday: Int { (rawValue + 1) % 7 + 1 }

    /// This weekday's bit in a schedule's weekday mask.
    public var bit: Weekdays { Weekdays(rawValue: 1 << rawValue) }

    /// The seven weekdays, starting with `firstWeekday` (a `Calendar` weekday number).
    public static func ordered(firstWeekday: Int) -> [Weekday] {
        let first = Weekday(calendarWeekday: firstWeekday) ?? .monday
        return (0..<7).compactMap { Weekday(rawValue: (first.rawValue + $0) % 7) }
    }
}
