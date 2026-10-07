import Core
import Foundation

/// Reads and writes the single settings row (SPEC §4.5, F-16).
@MainActor
final class SettingsManager {
    private let store: any TaskStore
    private let refresh: RefreshManager

    init(store: any TaskStore, refresh: RefreshManager) {
        self.store = store
        self.refresh = refresh
    }

    /// The settings, creating the row with the defaults the first time (SPEC §4.5).
    @discardableResult
    func loadOrCreate() throws -> SettingsValue {
        if let existing = try store.settings() {
            return existing
        }
        Log.settings.info("Creating the settings row with the defaults")
        return try store.save(SettingsValue.defaults)
    }

    /// Saves new settings. They must follow the rules in SPEC F-02 and F-16.
    @discardableResult
    func update(_ settings: SettingsValue) throws -> SettingsValue {
        if let error = settings.validationError {
            throw SettingsError.invalid(error)
        }
        let saved = try store.save(settings)
        refresh.afterChange()
        return saved
    }
}
