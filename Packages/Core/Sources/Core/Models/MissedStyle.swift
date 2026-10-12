/// How missed tasks are shown: Gentle ("Not done", grey, no badge or popup) or Strict ("Missed", red, with a badge
/// and the popup). It never changes statuses, the missed queries or the stats (SPEC F-30).
public enum MissedStyle: String, CaseIterable, Hashable, Sendable {
    case gentle
    case strict

    /// Gentle, the default.
    public static let `default` = MissedStyle.gentle

    /// Reads `settings.missed_style` (§4.5). Anything else is Gentle.
    public init(storedValue: String) {
        self = MissedStyle(rawValue: storedValue) ?? .default
    }
}

extension MissedStyle: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(storedValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
