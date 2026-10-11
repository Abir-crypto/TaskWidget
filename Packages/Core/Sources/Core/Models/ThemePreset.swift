/// The preset theme colors (SPEC F-27), with the names stored in `settings.tint_color` (§4.5). The names never
/// change once shipped.
public enum ThemePreset: String, CaseIterable, Hashable, Codable, Sendable {
    case blue
    case indigo
    case purple
    case pink
    case red
    case orange
    case green
    case teal
}
