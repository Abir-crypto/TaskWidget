import Core

/// Why new settings were rejected.
enum SettingsError: Error, Equatable {
    case invalidParts(PartSettingsError)
}
