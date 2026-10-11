import Core
import Foundation
import Observation

/// State for the tab layout: the Missed tab's badge and the theme color (SPEC F-27).
@Observable
@MainActor
final class RootViewModel {
    private(set) var missedCount = 0
    private(set) var theme = ThemeColor.default

    private let missed: MissedManager
    private let settings: SettingsManager

    init(missed: MissedManager, settings: SettingsManager) {
        self.missed = missed
        self.settings = settings
    }

    func load() {
        missedCount = missed.missedTodayCount()
        do {
            theme = try settings.loadOrCreate().tintColor
        } catch {
            Log.settings.error("Couldn't read the theme color: \(error)")
        }
    }
}
