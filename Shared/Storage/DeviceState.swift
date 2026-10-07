import Core
import Foundation

/// State that stays on this device and is never synced (SPEC §4.6): the timer, the missed popup's seen
/// list and the pending open action. Stored as JSON in the App Group's `UserDefaults`, so the app and the
/// widget extension share it (ios.md §6).
final class DeviceState: @unchecked Sendable {
    // `UserDefaults` is thread-safe; it's the only stored property.
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The App Group's shared defaults. Falls back to the app's own defaults if the group is unavailable.
    static let shared: DeviceState = {
        guard let defaults = UserDefaults(suiteName: StoreFactory.appGroup) else {
            Log.deviceState.error("App Group defaults unavailable; using standard defaults")
            return DeviceState(defaults: .standard)
        }
        return DeviceState(defaults: defaults)
    }()

    enum Key: String, CaseIterable {
        case timer = "deviceState.timer"
        case missedSeen = "deviceState.missedSeen"
        case pendingOpenAction = "deviceState.pendingOpenAction"
    }

    /// The one timer, or `nil` when idle.
    var timer: TimerState? {
        get { read(TimerState.self, for: .timer) }
        set { write(newValue, for: .timer) }
    }

    /// The missed tasks the popup has already shown.
    var missedSeen: MissedSeenList? {
        get { read(MissedSeenList.self, for: .missedSeen) }
        set { write(newValue, for: .missedSeen) }
    }

    /// Written by widget buttons that open the app; read and cleared by the app.
    var pendingOpenAction: PendingOpenAction? {
        get { read(PendingOpenAction.self, for: .pendingOpenAction) }
        set { write(newValue, for: .pendingOpenAction) }
    }

    /// Removes every device-only value.
    func reset() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    private func read<Value: Decodable>(_ type: Value.Type, for key: Key) -> Value? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Log.deviceState.error("Couldn't decode \(key.rawValue, privacy: .public): \(error)")
            return nil
        }
    }

    private func write<Value: Encodable>(_ value: Value?, for key: Key) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(value), forKey: key.rawValue)
        } catch {
            Log.deviceState.error("Couldn't encode \(key.rawValue, privacy: .public): \(error)")
        }
    }
}
