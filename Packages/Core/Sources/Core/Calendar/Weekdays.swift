/// A set of weekdays, stored as the bitmask in SPEC §4.2: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64.
public struct Weekdays: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ days: [Weekday]) {
        self = days.reduce(into: Weekdays()) { $0.insert($1.bit) }
    }

    public static let monday = Weekdays(rawValue: 1)
    public static let tuesday = Weekdays(rawValue: 2)
    public static let wednesday = Weekdays(rawValue: 4)
    public static let thursday = Weekdays(rawValue: 8)
    public static let friday = Weekdays(rawValue: 16)
    public static let saturday = Weekdays(rawValue: 32)
    public static let sunday = Weekdays(rawValue: 64)

    /// Every day of the week (127). The default for new habits (SPEC F-03).
    public static let all = Weekdays(rawValue: 127)

    /// The value stored for one-time tasks (SPEC §4.2).
    public static let none = Weekdays([])

    public func contains(_ weekday: Weekday) -> Bool {
        contains(weekday.bit)
    }

    /// The selected days, Monday first.
    public var days: [Weekday] {
        Weekday.allCases.filter { contains($0) }
    }
}
