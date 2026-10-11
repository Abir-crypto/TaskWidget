/// Whether the app follows the system's light or dark mode, or always uses one of them (SPEC F-28).
public enum Appearance: String, CaseIterable, Hashable, Sendable {
    case system
    case dark
    case light

    /// System, the default.
    public static let `default` = Appearance.system

    /// Reads `settings.appearance` (§4.5). Anything else is System.
    public init(storedValue: String) {
        self = Appearance(rawValue: storedValue) ?? .default
    }
}

extension Appearance: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(storedValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
