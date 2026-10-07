import Core
import Foundation
import Observation

/// State for Settings (SPEC F-16). Every change is saved straight away.
@Observable
@MainActor
final class SettingsViewModel {
    private(set) var settings: SettingsValue = .defaults
    /// `nil` until the system has answered.
    private(set) var permission: NotificationPermission?

    private let manager: SettingsManager
    private let notifications: any NotificationScheduling

    init(manager: SettingsManager, notifications: any NotificationScheduling) {
        self.manager = manager
        self.notifications = notifications
    }

    func load() async {
        do {
            settings = try manager.loadOrCreate()
        } catch {
            Log.settings.error("Couldn't load settings: \(error)")
        }
        permission = await notifications.permission()
    }

    /// The start times a part can be moved to without breaking the F-02 rules.
    func allowedStarts(for part: DayPart) -> ClosedRange<Int>? {
        let starts = settings.parts.allowedStarts(for: part)
        guard let first = starts.first, let last = starts.last else { return nil }
        return first...last
    }

    func setStart(of part: DayPart, to minute: Int) {
        update { settings in
            settings.parts = settings.parts.setting(part, to: minute)
            // Night moving past the recap carries the recap along (D-066).
            settings = settings.keepingRecapInRange()
        }
    }

    /// Applies a change and saves it. A change that breaks a rule isn't saved, and the screen shows what's stored.
    func update(_ change: (inout SettingsValue) -> Void) {
        var changed = settings
        change(&changed)
        guard changed != settings else { return }
        do {
            settings = try manager.update(changed)
        } catch {
            Log.settings.error("Rejected settings change: \(error)")
            Task { await load() }
        }
    }

    func requestPermission() async {
        _ = await notifications.requestPermission()
        permission = await notifications.permission()
    }

    /// "1.0 (1)".
    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
