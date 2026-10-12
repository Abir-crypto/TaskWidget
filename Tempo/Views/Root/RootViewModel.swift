import Core
import Foundation
import Observation

/// State for the tab layout: the Missed tab's badge, the theme color, the appearance and the missed style
/// (SPEC F-27, F-28, F-30).
@Observable
@MainActor
final class RootViewModel {
    private(set) var missedCount = 0
    private(set) var theme = ThemeColor.default
    private(set) var appearance = Appearance.default
    private(set) var missedStyle = MissedStyle.default

    private let missed: MissedManager
    private let settings: SettingsManager

    init(missed: MissedManager, settings: SettingsManager) {
        self.missed = missed
        self.settings = settings
    }

    func load() {
        missedCount = missed.missedTodayCount()
        do {
            let value = try settings.loadOrCreate()
            theme = value.tintColor
            appearance = value.appearance
            missedStyle = value.missedStyle
        } catch {
            Log.settings.error("Couldn't read the theme: \(error)")
        }
    }
}
