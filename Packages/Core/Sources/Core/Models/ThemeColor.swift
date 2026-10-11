/// The app's theme color (SPEC F-27): a preset, or a custom color in 8-bit sRGB components.
public enum ThemeColor: Hashable, Sendable {
    case preset(ThemePreset)
    case custom(red: Int, green: Int, blue: Int)

    /// Blue, the default.
    public static let `default` = ThemeColor.preset(.blue)

    /// Reads `settings.tint_color` (§4.5): a preset's name or `#RRGGBB`. Anything else is Blue.
    public init(storedValue: String) {
        if let preset = ThemePreset(rawValue: storedValue) {
            self = .preset(preset)
            return
        }
        let digits = storedValue.dropFirst()
        guard storedValue.first == "#", digits.count == 6, digits.allSatisfy(\.isHexDigit),
            let value = Int(digits, radix: 16)
        else {
            self = .default
            return
        }
        self = .custom(red: (value >> 16) & 0xFF, green: (value >> 8) & 0xFF, blue: value & 0xFF)
    }

    /// The value for `settings.tint_color`: the preset's name, or `#RRGGBB` with each component clamped to 0–255.
    public var storedValue: String {
        switch self {
        case .preset(let preset):
            return preset.rawValue
        case .custom(let red, let green, let blue):
            let hex = [red, green, blue].map { component -> String in
                let text = String(min(max(component, 0), 255), radix: 16, uppercase: true)
                return text.count == 1 ? "0" + text : text
            }
            return "#" + hex.joined()
        }
    }
}

extension ThemeColor: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(storedValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storedValue)
    }
}
